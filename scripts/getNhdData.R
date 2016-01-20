# gets the data based on states included in the yaml file
# unzips the geodatabases
# extracts the NHDWaterbody layer
# adds a column for the state name
# writes out a shapefile

library(yaml)
library(rgdal)
library(plyr)
library(dplyr)

load_nhd_config <- function(){
  yaml.load_file("config.yml")
}

write_nhd_shp <- function(){
  config = load_nhd_config
  serviceEndpoint <- config$serviceEndpoint
  prefix <- config$filename_prefix
  res <- config$filename_resolution
  suffix <- config$filename_suffix
  states <- config$states
  filename=""
  
  for (i in 1:length(states)) {
    stateList <- states[[i]]
    filename[i] <- paste0(prefix,"_",res,"_",stateList[2],"_",stateList[1],"_",suffix)
    download.file(url=paste0(serviceEndpoint,filename[i]), destfile = paste0(getwd(),"/data/",filename[i]), method="libcurl", quiet=FALSE)
    unzip(zipfile = paste0(getwd(),"/data/",filename[i]), exdir="data")
    split <- unlist(strsplit(filename[i],"\\."))
    fc <- readOGR(dsn=paste0(getwd(),"/data/",split[[1]],"/",split[[1]],".gdb"),layer="NHDWaterbody")
    fc$state <- as.character(states[[i]][1])
    writeOGR(fc,dsn = paste0(getwd(),"/data"), driver = "ESRI Shapefile",layer=paste0("NHDWaterbody_",stateList[1]),overwrite_layer = TRUE)
  }
}
