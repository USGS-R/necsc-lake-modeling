library(yaml)

config = yaml.load_file("config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- read.csv(file=paste0("sitesPermId",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure','id')]
  turbidity <- read.csv(file=paste0("turbidity",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','ActivityDepthHeightMeasure.MeasureValue','ActivityDepthHeightMeasure.MeasureUnitCode','ActivityStartDate','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
  turbiditySites <- merge(clarity, sites, by.x = "MonitoringLocationIdentifier", by.y = "MonitoringLocationIdentifier")
  write.csv(turbiditySites, file=paste0("turbiditySites",states[[i]]$fips,".csv"),row.names=FALSE)
}


