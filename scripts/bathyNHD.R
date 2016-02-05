library(rgdal)

config = yaml.load_file("config.yml")
states <- config$states

#get nhd layer
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#read in lagos data
input <- read.delim("bathybase_summary.tsv")

#subset state layer to our focal area
states <- readOGR(dsn = paste0(getwd(),"/statedata"), layer="cb_2014_us_state_5m")
wanted <- c("Minnesota","Michigan","Wisconsin") # TODO should be from config
states <- subset(states, NAME %in% wanted)

#identify the lat and lon values from data
coordinates(input) <- c("lon","lat")

#project to make comparable to the state layer
proj4string(input) <- CRS("+proj=longlat +ellps=WGS84") 
input <- spTransform(input, CRS(proj4string(states)))

#subset the bathybase data by state layer
input_subset <- input[states, ]
writeOGR(input_subset, driver = "ESRI Shapefile",layer="bathybase",overwrite_layer = TRUE, dsn=getwd())

input<-as.data.frame(input_subset)

#get the matches between the lat lng pairs from input layer and nhd
for (i in 1:nrow(input)) {
  x <- as.numeric(input$lon[i])
  y <- as.numeric(input$lat[i])
  xy <- cbind(x,y)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
  inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
  pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
  prmnn_i <- as.character(pts$nhd)
  input$id[i] <- prmnn_i
}

#write out original for safekeeping
write.csv(input[,c("bathybaseid","depth_max","lon","lat","id")], file = "bathynhd.csv", row.names = FALSE)

input<-as.data.frame(input)

#remove na values
input<-subset(input,!is.na(id))

#alter id field
input <- transform(input,id=paste0('nhd_',id))

write.csv(input[,c("bathybaseid","depth_max","lon","lat","id")], file = "bathynhd_final.csv", row.names = FALSE)

#write out some summary depth details
input$source <- "bathybase"
input$type <- ""

#if the file isn't there, use the column names
if (!file.exists("data/depth_data/depth_data_summary.csv")){
  write.table(input[,c("id","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append=TRUE,sep=",")
} else {
  #read in existing file, check for our current source and drop the rows if it's already there
  depth <- read.csv(file="data/depth_data/depth_data_summary.csv")
  depth <- subset(depth, source!="bathybase")
  #drop the original file now
  file.remove("data/depth_data/depth_data_summary.csv")
  #write the old rows back
  write.table(depth, file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append = TRUE, sep=",")
  #put the redone rows back for this source
  write.table(input[,c("id","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append = TRUE, sep=",", col.names = FALSE)
}


