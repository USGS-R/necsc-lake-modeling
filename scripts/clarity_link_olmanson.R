library(rgdal)
library(rgeos)
library(reshape2)

filename <- "lakesMNWQ_1975_2008_fill1975-epsg4326.zip"
temp.dir <- file.path(tempdir())
destfile <- file.path(temp.dir, filename)
download.file(url=paste0("http://portal.gis.umn.edu/download/",filename), destfile=destfile, method="libcurl", quiet=FALSE)
unzip(zipfile=destfile, exdir=temp.dir)

shpfile <- "MNWQ_1975_2008_fill1975-epsg4326"
lakes_olmanson <- readOGR(dsn=temp.dir, layer=shpfile)

clarity_link_olmanson <- function(lakes_olmanson) {
 
  #get centroids for lakes
  centroids <- SpatialPointsDataFrame(gCentroid(lakes_olmanson, byid=TRUE), lakes_olmanson@data, match.ID=FALSE)
  
  #map to nhd permid
  centroids$id <- link_to_nhd(centroids$y, centroids$x)
  centdf <- as.data.frame(centroids)
  
  #keep only non-nas
  centdf <- subset(centdf, id != 'nhd_NA')
  
  #keep non nas for the mean columns and write to file if so -- "X1975MEAN" "X1985MEAN" "X1990MEAN" "X1995MEAN" "X2000MEAN" "X2005MEAN" "X2008MEAN"
  cols <- c("X1975MEAN","X1985MEAN","X1990MEAN","X1995MEAN","X2000MEAN","X2005MEAN","X2008MEAN")
  temp <- centdf[!rowSums(is.na(centdf[cols])), ]
  temp$`source` <- "Olmanson_ea_2008"
  temp$type <- "satellite"
  temp <- temp[,c("id","source","type","X1975MEAN","X1985MEAN","X1990MEAN","X1995MEAN","X2000MEAN","X2005MEAN","X2008MEAN")]  
  keep <- melt(temp, id.vars = c("id","source","type"))
  names(keep) <- c("id","source","type","date","secchi")
  keep$date <- gsub("X", "",keep$date)
  keep$date <- gsub("MEAN","",keep$date)
  keep$date <- paste0(keep$date,"-","07-01")
  write.table(keep, 'data/secchi_data_linked/secchi_olmanson.tsv', sep=',', row.names=FALSE)
}