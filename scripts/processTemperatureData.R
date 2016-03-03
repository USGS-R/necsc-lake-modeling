library(yaml)

config = yaml.load_file("config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- read.csv(file=paste0("data/wqp_nhd/sitesPermId",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure','id')]
  temperature <- read.csv(file=paste0("temperature",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','ActivityDepthHeightMeasure.MeasureValue','ActivityDepthHeightMeasure.MeasureUnitCode','ActivityStartDate','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
  temperatureSites <- merge(temperature, sites, by.x = "MonitoringLocationIdentifier", by.y = "MonitoringLocationIdentifier")
  write.csv(temperatureSites, file=paste0("temperatureSites",states[[i]]$fips,".csv"),row.names=FALSE)
}
