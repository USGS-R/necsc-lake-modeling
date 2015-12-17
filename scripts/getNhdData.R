library(yaml)

config = yaml.load_file("config.yml")
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
}

