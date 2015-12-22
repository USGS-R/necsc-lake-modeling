require(rgdal)
require(dplyr)
require(sp)
require(maptools)
require(rgeos)


#get list of gdb we have
dirs <- as.data.frame(list.dirs(path = paste0(getwd(),"/data"), full.names = TRUE, recursive = TRUE), stringsAsFactors = FALSE)
colnames(dirs) <- "paths"
dirs <- as.data.frame(filter(dirs, grepl('gdb', paths)))

#grab each of the NHDWaterbody layers from the gdb and make them shapefiles
for (i in 1:nrow(dirs)) {
  fgdb <- dirs[i,]
  fc <- readOGR(dsn=fgdb,layer="NHDWaterbody")
  writeOGR(fc,dsn = paste0(getwd(),"/data"), driver = "ESRI Shapefile",layer=paste0("NHDWaterbody_",i),overwrite_layer = TRUE)
}


#merge the shapefiles based on http://stackoverflow.com/questions/5201458/making-a-choropleth-in-r-merging-zip-code-shapefiles-from-multiple-states/5227384#5227384
mergePolys <- function () {
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
  
  #this file has duplicates
  #writeOGR(nhdwaterbody, driver = "ESRI Shapefile",layer="NHDWaterbody_merged",overwrite_layer = TRUE, dsn=getwd())
  #remove duplicates

  plot(nhdwaterbody)
  
}
