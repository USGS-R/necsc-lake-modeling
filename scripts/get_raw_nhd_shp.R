# gets the data based on states included in the yaml file
# unzips the geodatabases
# extracts the NHDWaterbody layer
# adds a column for the state name
# writes out a shapefile
# returns a list that includes dir and the shp layers

write_nhd_shp <- function(config){
  serviceEndpoint <- config$serviceEndpoint
  prefix <- config$filename_prefix
  res <- config$filename_resolution
  suffix <- config$filename_suffix
  states <- config$states
  
  data.dir <- file.path(tempdir(),'NHD')
  temp.dir <- file.path(tempdir(),'temp')
  dir.create(data.dir)
  for (i in 1:length(states)) {
    dir.create(temp.dir)
    state <- states[[i]][['name']]
    fips <- states[[i]][['fips']]
    
    filename <- paste0(prefix,"_",res,"_",fips,"_",state,"_",suffix)
    destfile <- file.path(temp.dir,filename)
    download.file(url=paste0(serviceEndpoint,filename), destfile = destfile, method="libcurl", quiet=FALSE)
    unzip(zipfile = destfile, exdir=temp.dir)
    unlink(destfile)
    shp.name <- strsplit(filename,"\\.")[[1]][1]
    suppressWarnings(fc <- rgdal::readOGR(dsn=file.path(temp.dir, shp.name, paste0(shp.name,".gdb")),layer="NHDWaterbody"))
    fc$state <- state
    suppressWarnings(rgdal::writeOGR(fc, dsn = data.dir, driver = "ESRI Shapefile",layer=paste0("NHDWaterbody_", state),overwrite_layer = TRUE))
    unlink(temp.dir)
  }
  return(list('data.dir'=data.dir, layers=paste0("NHDWaterbody_", sapply(states,function(x)x$name))))
}
