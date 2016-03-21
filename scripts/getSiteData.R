library(dataRetrieval)
library(rgdal)

nhd_config = load_config("configs/NHD_config.yml")
wqp_config = load_config("configs/wqp_config.yml")

states <- nhd_config$states

for (i in 1:length(states)) {  
  sites <- whatWQPsites(siteType = wqp_config$siteType, statecode = paste0("US:",states[[i]]$fips)) 
  write.csv(sites, file=paste0("data/wqp_sites/sites",states[[i]]$fips,".csv"),row.names=FALSE)
} 

#read in nhd data
nhd <- readOGR(dsn = "data", layer="NHDWaterbody")

#match with NHD permid, if there is no match, the id field is NA
for (j in 1:length(states)) {
  wqp_sites <- read.csv(file=paste0("data/wqp_sites/sites",states[[j]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure')]
  wqp_sites <- wqp_sites[!duplicated(wqp_sites),]
  for (i in 1:nrow(wqp_sites)) {
    lat <- as.numeric(wqp_sites$LatitudeMeasure[i])
    lng <- as.numeric(wqp_sites$LongitudeMeasure[i])
    xy <- cbind(lng,lat)
    pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
    inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
    pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
    prmnn_i <- as.character(pts$nhd)
    wqp_sites$id[i] <- prmnn_i
    print(i)
  }
  for (k in 1:nrow(wqp_sites)) {
    if (!is.na(wqp_sites$id[k])) {
      wqp_sites$id[k] <- paste0("nhd_",wqp_sites$id[k])
    }
  }
  
  write.csv(wqp_sites, file=paste0("data/wqp_nhd/sitesPermId",states[[j]]$fips,".csv"),row.names=FALSE) 
}

#join all the site files for use as a lookup table
#lookup <- data.frame(stringsAsFactors = FALSE)
lookup <- data.frame()
for (j in 1:length(states)) { 
  nhd_wqp <- read.csv(file=paste0("data/wqp_nhd/sitesPermId",states[[j]]$fips,".csv"))
  if (length(nhd_wqp)>0) {
    lookup <- rbind(lookup, as.data.frame(nhd_wqp), stringsAsFactors=FALSE)
  }
}  

saveRDS(lookup, file="data/wqp_nhd/wqp_nhdLookup.rds")



