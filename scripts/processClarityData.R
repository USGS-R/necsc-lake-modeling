# 1) get the site data from WQP (whatWQPsites)
# 2) merge with the clarity data monitoringlocation info captured with getClarityData.R (mhines-usgs/necsc-lake-modeling: 0b81c6b)
# 3) subset to keep lat, long, secchi data value and permid

library(dataRetrieval)
library(yaml)
library(rgdal)

config = yaml.load_file("config.yml")
states <- config$states

getSiteData <- function() {
  for (i in 1:length(states)) { 
    sites <- whatWQPsites(statecode = paste0("US:",states[[i]]$fips))
    write.csv(sites, file=paste0("sites",states[[i]]$fips,".csv"),row.names=FALSE)
  } 
}

matchWithClarity <- function() {
  for (i in 1:length(states)) { 
    sites <- read.csv(file=paste0("sites",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','MonitoringLocationName','ProviderName','LatitudeMeasure','LongitudeMeasure')]
    clarity <- read.csv(file=paste0("secchiDiskDepth",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','ActivityDepthHeightMeasure.MeasureValue','ActivityDepthHeightMeasure.MeasureUnitCode','ActivityStartDate','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
    claritySites <- merge(clarity, sites, by.x = "MonitoringLocationIdentifier", by.y = "MonitoringLocationIdentifier")
    write.csv(claritySites, file=paste0("claritySites",states[[i]]$fips,".csv"),row.names=FALSE)
  }
}



#get the prmnn_i from nhd for lake/polygon for each row
getPermId <- function() { 
  nhd <- readOGR(dsn = paste0(getwd(),"/data"), layer="NHDWaterbody_unique")
  for (j in 1:length(states)) {
    sites <- read.csv(file=paste0("claritySites",states[[j]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure')]
    sites <- sites[!duplicated(sites),]
    for (i in 1:nrow(sites)) {
      lat <- as.numeric(sites$LatitudeMeasure[i])
      lng <- as.numeric(sites$LongitudeMeasure[i])
      xy <- cbind(lng,lat)
      pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
      inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
      pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
      prmnn_i <- as.character(pts$nhd)
      sites$Permnn_I[i] <- prmnn_i
    }
    write.csv(sites, file=paste0("claritySitesWithNHD",states[[j]]$fips,".csv"),row.names=FALSE) 
  }
}