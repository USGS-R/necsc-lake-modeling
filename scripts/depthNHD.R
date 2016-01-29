library(rgdal)

#get nhd later
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

input <- read.delim("lake_info_subset.tsv")

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
write.csv(input[,c("permID","maxdepth")], file="lagosNHD.csv",row.names=FALSE) 

keepers <- subset(input, !is.na(maxdepth))
write.csv(keepers[,c("permID")], file="lagosPermID.csv",row.names=FALSE)
