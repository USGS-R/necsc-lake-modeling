library(rgdal)

#get nhd layer
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#read in lagos data
input <- read.delim("lake_depth_LAGOS.tsv")

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
  print(i)
}

#back up the file
write.csv(input, file="tempLake_info_subset_linked.csv",row.names=FALSE)

input<-as.data.frame(input)

input<-subset(input,!is.na(id))

#prefix id with source
input2 <- transform(input,id=paste0('nhd_',id))

#write out file for JR with just permids where we have depth data
write.csv(input2[,c("id","maxdepth")], file="lagosNHD.csv",row.names=FALSE) 

#write out entire file with nhd permid
write.csv(input2, file="lake_depth_LAGOS_linked.csv",row.names=FALSE)

#get just the ids we have depth data for from LAGOS
keepers <- as.data.frame(input)
cols <- c("id")
keepers <- keepers[,cols,drop=FALSE]
keepers <- transform(keepers,id=paste0('nhd_',id))

write.csv(keepers, file="depth_summary_LAGOS.csv",row.names=FALSE)

#write out some summary depth details
input2$source <- "lagos"
input2$type <- "maxdepth"

#if the file isn't there, use the column names
if (!file.exists("data/depth_data/depth_data_summary.csv")){
  write.table(input2[,c("id","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append=TRUE,sep=",")
} else {
  #read in existing file, check for our current source and drop the rows if it's already there
  depth <- read.csv(file="data/depth_data/depth_data_summary.csv")
  depth <- subset(depth, source!="lagos")
  #drop the original file now
  file.remove("data/depth_data/depth_data_summary.csv")
  #write the old rows back
  write.table(depth, file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append = TRUE, sep=",")
  #put the redone rows back for this source
  write.table(input2[,c("id","source","type")], file="data/depth_data/depth_data_summary.csv", row.names = FALSE, append = TRUE, sep=",", col.names = FALSE)
}


