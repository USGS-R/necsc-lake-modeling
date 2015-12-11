##just a pile of experiments at this point

library(dataRetrieval)
library(dplyr)
library(leaflet)

#get the water data
#78 obs 11/20/2015
temperatureSample <- readWQPdata(statecode="US:26",characteristicName="Temperature, sample", siteType="Lake, Reservoir, Impoundment")
write.csv(temperatureSample,"temperatureSample_26.csv",row.names=FALSE)

#733999 obs 11/20/2015
temperatureWater <- readWQPdata(statecode="US:26",characteristicName="Temperature, water", siteType="Lake, Reservoir, Impoundment")
write.csv(temperatureWater,"temperatureWater_26.csv",row.names=FALSE)

#subset only the fields we want
temperatureSample <- read.csv(file = "temperatureSample.csv", sep = ",")[ ,c('ActivityStartDate','ActivityStartTime.Time','ActivityStartTime.TimeZoneCode','ActivityBottomDepthHeightMeasure.MeasureValue','ActivityBottomDepthHeightMeasure.MeasureUnitCode','MonitoringLocationIdentifier','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]

temperatureWater <- read.csv(file = "temperatureWater.csv", sep = ",")[ ,c('ActivityStartDate','ActivityStartTime.Time','ActivityStartTime.TimeZoneCode','ActivityBottomDepthHeightMeasure.MeasureValue','ActivityBottomDepthHeightMeasure.MeasureUnitCode','MonitoringLocationIdentifier','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]

#merge the two files into a dataframe
tempdf <- as.data.frame(temperatureSample)
tempdf <- rbind(temperatureWater, tempdf)

#get minnesota site data
sites <- whatWQPsites(stateCd="MN")
write.csv(sites,"mnSites.csv",row.names=FALSE)
#subset minnesota site data
sitesMn <- read.csv(file="mnSites.csv",sep=",")[ ,c('MonitoringLocationIdentifier','MonitoringLocationName','ProviderName','LatitudeMeasure','LongitudeMeasure')]

#join site data to temperature data
#merge(df1, df2, by = "CustomerId")
merged <- merge(tempdf, as.data.frame(sitesMn), by="MonitoringLocationIdentifier")

# get lat lon for each site
locations <- group_by(merged,MonitoringLocationIdentifier, MonitoringLocationName) %>% summarize(lat = mean(LatitudeMeasure), lon = mean(LongitudeMeasure), count=length(unique(ActivityStartDate)))

MN.sites = dplyr::mutate(locations, popup = sprintf("%s </br>Date count: %s", MonitoringLocationName, count))
save('MN.sites',file = 'data/MN_sites.RData')

m = leaflet(MN.sites) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addCircleMarkers(popup = ~popup, color = 'blue', radius=4)
m  

temperatureWater <- read.csv(file = "temperatureWater_26.csv", sep = ",")[ ,c('ActivityStartDate','ActivityStartTime.Time','ActivityStartTime.TimeZoneCode','ActivityBottomDepthHeightMeasure.MeasureValue','ActivityBottomDepthHeightMeasure.MeasureUnitCode','MonitoringLocationIdentifier','ResultMeasureValue','ResultMeasure.MeasureUnitCode')]
sites <- whatWQPsites(stateCd="MI")
write.csv(sites,"miSites.csv",row.names=FALSE)
#subset minnesota site data
sitesMi <- read.csv(file="miSites.csv",sep=",")[ ,c('MonitoringLocationIdentifier','MonitoringLocationName','ProviderName','LatitudeMeasure','LongitudeMeasure')]


merged <- merge(temperatureWater, as.data.frame(sitesMi), by="MonitoringLocationIdentifier")

# get lat lon for each site
locations <- group_by(merged,MonitoringLocationIdentifier, MonitoringLocationName) %>% summarize(lat = mean(LatitudeMeasure), lon = mean(LongitudeMeasure), count=length(unique(ActivityStartDate)))

MI.sites = dplyr::mutate(locations, popup = sprintf("%s </br>Date count: %s", MonitoringLocationName, count))
save('MI.sites',file = 'data/MI_sites.RData')

#get site count -- how many records total do we have?
tempMn <- group_by(merged, MonitoringLocationIdentifier)
siteCount <- summarise(tempMn,
                   count=n())
#add to original table
tempdf <- merge(merged, as.data.frame(siteCount), by="MonitoringLocationIdentifier")

#get unique temp dates per site 
dateUn <- group_by(merged, MonitoringLocationIdentifier, ActivityStartDate)
dateCount <- summarise(dateUn,
                       count=n())

#get number of unique dates for samples per site - how many unique sampling dates do we have?
bydate <- group_by(dateCount, MonitoringLocationIdentifier)
summary.bydate <- summarise(bydate,
                            count.ActivityStartDate=n())

#add to original table
tempdf <- merge(tempdf, as.data.frame(summary.bydate), by="MonitoringLocationIdentifier")

#save it
write.csv(tempdf,"sitetempdata.csv",row.names=FALSE)


# doesn't work but this is what I want to do
getDates <- function(tempdf, site) {
  
  earliest <- filter(tempdf, MonitoringLocationIdentifier==site)
  latest <- filter(tempdf, MonitoringLocationIdentifier==site & max(ActivityStartDate.x))

  return(list(earliest=earliest,latest=latest))
  
}