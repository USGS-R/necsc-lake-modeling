library(yaml)

config = yaml.load_file("config.yml")
states <- config$states

for (i in 1:length(states)) { 
  sites <- read.csv(file=paste0("sitesPermId",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','LatitudeMeasure','LongitudeMeasure','id')]
  chlorophyll <- read.csv(file=paste0("chlorophyll",states[[i]]$fips,".csv"),sep=",")[ ,c('MonitoringLocationIdentifier','ActivityDepthHeightMeasure.MeasureValue','ActivityDepthHeightMeasure.MeasureUnitCode','ActivityStartDate','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
  chlorophyllSites <- merge(chlorophyll, sites, by.x = "MonitoringLocationIdentifier", by.y = "MonitoringLocationIdentifier")
  write.csv(chlorophyllSites, file=paste0("chlorophyllSites",states[[i]]$fips,".csv"),row.names=FALSE)
}