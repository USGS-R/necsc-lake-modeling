library(rgdal)

#get nhd layer
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#read in lagos data
input <- read.delim("lake_info_subset.tsv")

#get the matches between the lat lng pairs and nhd layer
for (i in 1:nrow(input)) {
  x <- as.numeric(input$nhd_long[i])
  y <- as.numeric(input$nhd_lat[i])
  xy <- cbind(x,y)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
  inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
  pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
  prmnn_i <- as.character(pts$nhd)
  input$permID[i] <- prmnn_i
}
input<-as.data.frame(input)
#write out file for LW with permid and maxdepth
write.csv(input[,c("permID","maxdepth")], file="lagosNHD.csv",row.names=FALSE) 

#write out file for JR with just permids where we have depth data
keepers <- as.data.frame(input)
cols <- c("permID")
keepers <- keepers[,cols,drop=FALSE]
keepers <- subset(keepers, !is.na(permID))
write.csv(keepers, file="lagosPermID.csv",row.names=FALSE)
