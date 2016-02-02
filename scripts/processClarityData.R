library(yaml)

config = yaml.load_file("config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- read.csv(file=paste0("sitesPermId",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure','id')]
  clarity <- read.csv(file=paste0("secchi",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','ActivityDepthHeightMeasure.MeasureValue','ActivityDepthHeightMeasure.MeasureUnitCode','ActivityStartDate','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
  claritySites <- merge(clarity, sites, by.x = "MonitoringLocationIdentifier", by.y = "MonitoringLocationIdentifier")
  write.csv(claritySites, file=paste0("claritySites",states[[i]]$fips,".csv"),row.names=FALSE)
}


