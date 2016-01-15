library(dataRetrieval)
library(yaml)
library(rgdal)

config = yaml.load_file("config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- whatWQPsites(statecode = paste0("US:",states[[i]]$fips))
  write.csv(sites, file=paste0("sites",states[[i]]$fips,".csv"),row.names=FALSE)
} 
