library(dataRetrieval)
library(yaml)
library(rgdal)

config = yaml.load_file("configs/NHD_config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- whatWQPsites(statecode = paste0("US:",states[[i]]$fips))
  write.csv(sites, file=paste0("sites",states[[i]]$fips,".csv"),row.names=FALSE)
}

#read in nhd data
nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody")

#match with NHD permid, if there is no match, the id field is NA
for (j in 1:length(states)) {
  sites <- read.csv(file=paste0("sites",states[[j]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure')]
  sites <- sites[!duplicated(sites),]
  for (i in 1:nrow(sites)) {
    lat <- as.numeric(sites$LatitudeMeasure[i])
    lng <- as.numeric(sites$LongitudeMeasure[i])
    xy <- cbind(lng,lat)
    pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
    inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
    pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
    prmnn_i <- as.character(pts$nhd)
    sites$id[i] <- prmnn_i
    print(i)
  }
  write.csv(sites, file=paste0(getwd(),"/data/wqp_nhd/sitesPermId",states[[j]]$fips,".csv"),row.names=FALSE) 
}

#join all the site files for use as a lookup table
lookup <- data.frame()
for (j in 1:length(states)) { 
  tryCatch({ 
    sites <- read.csv(file=paste0(getwd(),"/data/wqp_nhd/sitesPermId",states[[j]]$fips,".csv"))
    if (length(sites)>0) {
      lookup <- rbind(lookup, as.data.frame(sites))
    } 
    error = function(e){
      error <- paste("\n Request failed:", "on", as.character(Sys.time()), "\t", "State:",config$states[i],"Value:", e)
      cat(error, file="log.txt", append=TRUE)
    }
  })
} 

write.csv(lookup, file=paste0(getwd(),"/data/wqp_nhd/wqp_nhdLookup.csv"),row.names=FALSE)

