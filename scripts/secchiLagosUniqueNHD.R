library(rgdal)

#get nhd layer
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#read in lagos data
input <- read.delim("secchi_subset.tsv")

input2 <- input[,c("lagoslakeid","nhd_lat","nhd_long")]
input2 <- unique(input2)

#get the matches between the lat lng pairs and nhd layer
for (i in 1:nrow(input2)) {
  x <- as.numeric(input2$nhd_long[i])
  y <- as.numeric(input2$nhd_lat[i])
  xy <- cbind(x,y)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
  inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
  pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
  prmnn_i <- as.character(pts$nhd)
  input2$id[i] <- prmnn_i
  print(i)
}

input2 <- as.data.frame(input2)
input3 <- subset(input2,!is.na(id))
input3 <- transform(input3,id=paste0('nhd_',id))
#write out the mapping between lagoslakeid and nhd permid
write.csv(input3[,c("lagoslakeid","id")], file = "lagosnhd_final.csv", row.names = FALSE)

#merge with big secchi file
output <- merge(input, as.data.frame(input3), by.x = "lagoslakeid", by.y="lagoslakeid")
write.csv(output, file="secchi_subsetWithPermID.csv", row.names = FALSE)
