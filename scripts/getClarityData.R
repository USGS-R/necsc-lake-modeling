# Trying all these values from WQP http://www.waterqualitydata.us/Codes/Characteristicname?mimeType=xml
# <Code value="Depth, Secchi disk depth" providers="STORET"/>
# <Code value="Depth, Secchi disk depth (choice list)" providers="STORET"/>
# <Code value="Secchi Reading Condition (choice list)" providers="STORET"/>
# <Code value="Secchi depth" providers="STEWARDS"/>
# <Code value="Transparency, Secchi tube with disk" providers="STORET"/>
# <Code value="Transparency, tube with disk" providers="STORET"/>
# <Code value="Water transparency, Secchi disc" providers="NWIS"/>
# <Code value="Water transparency, tube with disk" providers="NWIS"/>

# uses the config.yml file to generate a list of states and grab the data using dataRetrieval calls

library(dataRetrieval)
library(yaml)


getClarityData <- function() {

  config = yaml.load_file("config.yml")
  states <- config$states
  
  for (i in 1:length(states)) {
  
    secchiDiskDepth <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Depth, Secchi disk depth", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiDiskDepth)>0) {
      write.csv(secchiDiskDepth, file = paste0("secchiDiskDepth",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    secchiDiskDepthChoice <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Depth, Secchi disk depth (choice list)", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiDiskDepthChoice)>0) {
      write.csv(secchiDiskDepthChoice, file = paste0("secchiDiskDepthChoice",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    secchiReadingConditionChoice <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Secchi Reading Condition (choice list)", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiReadingConditionChoice)>0) {
      write.csv(secchiReadingConditionChoice, file = paste0("secchiReadingConditionChoice",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    ##### no data
    secchiDepth <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Secchi depth", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiDepth)>0) {
      write.csv(secchiDepth, file = paste0("secchiDepth",states[[i]]$fips,".csv"),row.names=FALSE)
    }  
    
    ##### no data
    secchiTubeWithDisk <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Transparency, Secchi tube with disk", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiTubeWithDisk)>0) {
      write.csv(secchiTubeWithDisk, file = paste0("secchiTubeWithDisk",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    tubeWithDiskTrans <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Transparency, tube with disk", siteType="Lake, Reservoir, Impoundment")
    if (length(tubeWithDiskTrans)>0) {
      write.csv(tubeWithDiskTrans, file = paste0("tubeWithDiskTrans",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    secchiDiscWaterTrans <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Water transparency, Secchi disc", siteType="Lake, Reservoir, Impoundment")
    if (length(secchiDiscWaterTrans)>0) {
      write.csv(secchiDiscWaterTrans, file = paste0("secchiDiscWaterTrans",states[[i]]$fips,".csv"),row.names=FALSE)
    }
    
    ##### no data
    tubeDiskWaterTrans <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName="Water transparency, tube with disk", siteType="Lake, Reservoir, Impoundment")
    if (length(tubeDiskWaterTrans)>0) {
      write.csv(tubeDiskWaterTrans, file = paste0("tubeDiskWaterTrans",states[[i]]$fips,".csv"),row.names=FALSE)
    }
  
  } 

}
