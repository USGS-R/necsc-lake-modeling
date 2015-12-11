
##just a pile of experiments at this point

library(dataRetrieval)
library(dplyr)
library(zoo)
library(xts)


makeMap <- function() {
  
  df <- rbind(MI.sites, MN.sites)
  df$count <- log(df$count)
  
  pal <- colorNumeric(palette = c("darkblue","dodgerblue","green4","orange","red"), 
                      domain = df$count)
  
  m = leaflet(df) %>% 
    addProviderTiles("CartoDB.Positron") %>% 
    addCircleMarkers(popup = ~popup, color = ~pal(count), 
                     radius=4, stroke=FALSE, fillOpacity=0.7)
  m
  
}


getData <- function(data) {

#get the water data
temperatureSample <- readWQPdata(statecode="US:27",characteristicName="Temperature, sample", siteType="Lake, Reservoir, Impoundment")
write.csv(temperatureSample,"temperatureSample.csv",row.names=FALSE)
temperatureWater <- readWQPdata(statecode="US:27",characteristicName="Temperature, water", siteType="Lake, Reservoir, Impoundment")
write.csv(temperatureWater,"temperatureWater.csv",row.names=FALSE)

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
merged <- merge(tempdf, as.data.frame(sitesMn), by="MonitoringLocationIdentifier")

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

data <- tempdf

return(data)

}

#takes a site and the data and locates the earliest observation date and last observation date
getDates <- function(data, site) {
  
  sitedata <- filter(data, MonitoringLocationIdentifier==site)
  earliest <- first(sitedata, n=1)
  latest <- last(sitedata, n=1)

  return(list(earliest=earliest,latest=latest))
  
>>>>>>> 04e96b8e44e93645f4c601efe9b7ed65a720c07d
}