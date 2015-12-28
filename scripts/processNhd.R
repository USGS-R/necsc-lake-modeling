library(rgdal)
library(dplyr)
library(sp)
library(maptools)
library(rgeos)
library(magrittr)
library(plyr)

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

#retain polygons >= 4HA which equals 0.04 Sq Km
smallestArea <- 0.04
smallestAreaMask <- which(nhdwaterbody$AreSqKm >= smallestArea)
nhdFiltered <- nhdwaterbody[smallestAreaMask,]
writeOGR(nhdFiltered, driver = "ESRI Shapefile",layer="NHDWaterbody_filtered",overwrite_layer = TRUE, dsn=getwd())

#get only unique polygons
nhdUnique <- unionSpatialPolygons(nhdFiltered, nhdFiltered$Prmnn_I)

#Make a data frame that just has unique data from the original dataset
nhd_data <- nhdFiltered@data %>%
  group_by(Prmnn_I)
nhd_data <- distinct(nhd_data, Prmnn_I)  

#merge the polygons with the new data file
nhd <- SpatialPolygonsDataFrame(nhdUnique,data=data.frame(join(data.frame(Prmnn_I=names(nhdUnique)),nhd_data),row.names=row.names(nhdUnique)))
writeOGR(nhd, driver = "ESRI Shapefile",layer="NHDWaterbody_unique",overwrite_layer = TRUE, dsn=getwd())

#get centroids for data as dataframe
trueCentroids <- gCentroid(nhd,byid=TRUE)
trueCentDf <- as.data.frame(trueCentroids)
write.csv(trueCentDf, file = "nhd_centroids.csv")



