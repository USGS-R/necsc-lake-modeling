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
  input$id[i] <- prmnn_i
}

input<-as.data.frame(input)

input<-subset(input,!is.na(id))

#prefix id with source
input2 <- transform(input,id=paste0('nhd_',id))

#write out file for LW with permid and maxdepth
write.csv(input2[,c("id","maxdepth")], file="lagosNHD.csv",row.names=FALSE) 

#write out file for JR with just permids where we have depth data
keepers <- as.data.frame(input)
cols <- c("id")
keepers <- keepers[,cols,drop=FALSE]

write.csv(keepers, file="lagosPermID.csv",row.names=FALSE)

#TODO change to tsv and put in data/depth_data/depth_data_summary.csv
#write out some summary depth details
names(input2)[names(input2)=="maxdepth"] <- "zmax"
names(input2)[names(input2)=="id"] <- "nhd_id"
input2$source <- "lagos"
input2$type <- "maxdepth"
input2$id <- gsub("nhd_", "", input2$nhd_id)

#if the file isn't there, use the column names
if (!file.exists("data/depth_data/depth_data_summary.csv")){
  write.table(input2[,c("id","zmax","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append=TRUE,sep=",")
} else {
  write.table(input2[,c("id","zmax","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append = TRUE, sep=",", col.names = FALSE)
}


