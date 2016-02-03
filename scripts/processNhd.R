library(rgdal)
library(dplyr)
library(sp)
library(maptools)
library(rgeos)
library(magrittr)
library(plyr)
library(raster)

#merge the shapefiles
setwd(paste0(getwd(),"/data"))
uid <-1 
files <- list.files(pattern="*.shp$", recursive=TRUE, full.names=TRUE) 
nhdwaterbody <- readOGR(files[1], gsub("^.*/(.*).shp$", "\\1", files[1]))  
n <- length(slot(nhdwaterbody, "polygons"))  
nhdwaterbody <- spChFIDs(nhdwaterbody, as.character(uid:(uid+n-1)))
uid <- uid + n

for (i in 2:length(files)) {
  temp.data <- readOGR(files[i], gsub("^.*/(.*).shp$", "\\1",files[i]))
  n <- length(slot(temp.data, "polygons")) 
  temp.data <- spChFIDs(temp.data, as.character(uid:(uid+n-1))) 
  uid <- uid + n 
  nhdwaterbody <- spRbind(nhdwaterbody,temp.data) 
}

#this file has duplicates and all polygons from original
writeOGR(nhdwaterbody, driver = "ESRI Shapefile",layer="NHDWaterbody_merged",overwrite_layer = TRUE, dsn=getwd())

nhdwaterbody <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody_merged")

#subset merged nhdwaterbody by state
states <- readOGR(dsn = paste0(getwd(),"/statedata"), layer="cb_2014_us_state_5m")
wanted <- c("Minnesota","Michigan","Wisconsin") # should be from config
states <- subset(states, NAME %in% wanted)
states <- spTransform(states, CRS(proj4string(nhdwaterbody)))
nhdSubset <- nhdwaterbody[states, ]

writeOGR(nhdSubset, driver = "ESRI Shapefile",layer="NHDWaterbody_subset_states",overwrite_layer = TRUE, dsn=getwd())

#project it so we can calculate area - lambert equal area
newProj <- CRS("+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs")
nhdSubset <- spTransform(nhdSubset,newProj) 
nhdSubset$area <- gArea(nhdSubset, byid=TRUE) / 1000^2

#retain polygons >= 4HA which equals 0.04 Sq Km 
smallestArea <- 0.04 
smallestAreaMask <- which(nhdSubset$area >= smallestArea) 
nhdFiltered <- nhdSubset[smallestAreaMask,] 
writeOGR(nhdFiltered, driver = "ESRI Shapefile",layer="NHDWaterbody_filtered_size",overwrite_layer = TRUE, dsn=getwd()) 

#get only unique polygons, buffer to get rid of Topology Exception error
nhdBuff <- gBuffer(nhdFiltered, byid=TRUE, width=0)
nhdUnique <- unionSpatialPolygons(nhdBuff, nhdBuff$Prmnn_I)

#Make a data frame that just has unique data from the original dataset
nhd_data <- nhdFiltered@data %>%
  group_by(Prmnn_I)
nhd_data <- distinct(nhd_data, Prmnn_I)  

#merge the polygons with the new data file
nhd <- SpatialPolygonsDataFrame(nhdUnique,data=data.frame(join(data.frame(Prmnn_I=names(nhdUnique)),nhd_data),row.names=row.names(nhdUnique)))
writeOGR(nhd, driver = "ESRI Shapefile",layer="NHDWaterbody_unique",overwrite_layer = TRUE, dsn=getwd())

#make sure it's in WGS84
nhdProjected <- spTransform(nhd, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
writeOGR(nhdProjected, driver = "ESRI Shapefile",layer="NHDWaterbody_projected",overwrite_layer = TRUE, dsn=getwd())

#get centroids and write out
getCent <- gCentroid(nhdProjected,byid=TRUE)
getCentDf <- as.data.frame(getCent)
getCentDf <- cbind(Prmnn_I = rownames(getCentDf), getCentDf)
data <- merge(getCentDf, as.data.frame(nhdProjected), by.x = "Prmnn_I", by.y="Prmnn_I")
write.csv(data[,c("Prmnn_I","x","y","area","state")], file = "nhd_centroids.csv", row.names = FALSE)

#is centroid in the state? if not, NA will appear in state_id field in this table.
for (i in 1:nrow(data)) {
  lat <- as.numeric(data$y[i])
  lng <- as.numeric(data$x[i])
  xy <- cbind(lng,lat)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(states)))
  inside.nhd <- !is.na(over(pts, as(states, "SpatialPolygons"))) 
  pts$nhd <- over(pts, states, fn = NULL, returnList = FALSE)$STATEFP
  state_id <- as.character(pts$nhd)
  data$state_id[i] <- state_id
}

#get only data for those where NA is not state_id
keepers <- subset(data, !is.na(state_id))
#join it with the shapefile
nhdProjected@data <- left_join(nhdProjected@data, keepers)
writeOGR(nhdProjected, driver = "ESRI Shapefile",layer="NHDWaterbody_near_final",overwrite_layer = TRUE, dsn=getwd())

#drop na state_id
nhdProjected<-subset(nhdProjected, !is.na(state_id))
writeOGR(nhdProjected, driver = "ESRI Shapefile",layer="NHDWaterbody",overwrite_layer = TRUE, dsn=getwd())

#nhdwaterbody <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#remove any polygons on the blacklist
blacklist <- c("166766705","167671341","166766729","120053594","166766612","120053704","120052448","120054088","166766604","120052980","167671322","166766762","120053592","120053269","166766774","11938419","120053611","120053261","120053588","167671352","120053580","12222568","120053608","120052958","120054093","120054117","120053120","11937803","167671314","120054116","7115637","120054125","120054094","120054118","15633645","120054114","120054090","120054122","120054123","120054092","120053703","120054120","120054124","120054089","120054121","120054113","120054126","120054119","26917632","12213213","6800970","7748124","12219432","13203571","4792756","13054280","12027790","12953770","11946129","13063609","12953774","14441968","12213419","13203363","12213453","4792438","6790727","120052964","166766782")

nhdFinal <- nhdProjected[!nhdwaterbody$Prmnn_I %in% blacklist,]

writeOGR(nhdFinal, driver = "ESRI Shapefile",layer="NHDWaterbody",overwrite_layer = TRUE, dsn=paste0(getwd(),"/data"))

#transform prmnn_i to id and append source info into column
nhdwaterbody <- as.data.frame(nhdwaterbody)
names(nhdwaterbody)[names(nhdwaterbody)=="Prmnn_I"] <- "id"
names(nhdwaterbody)[names(nhdwaterbody)=="y"] <- "lat"
names(nhdwaterbody)[names(nhdwaterbody)=="x"] <- "lon"
nhdwaterbody <- transform(nhdwaterbody,id=paste0('nhd_',id))
write.csv(nhdwaterbody[,c("id","lon","lat","area","state")], file = paste0(getwd(),"/data/NHD_Summ/nhd_centroids.csv"), row.names = FALSE)
