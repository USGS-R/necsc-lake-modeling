# <Code value="Turbidity" providers="NWIS STEWARDS STORET"/>
# <Code value="Turbidity severity" providers="NWIS"/>
# <Code value="Turbidity severity (choice list)" providers="STORET"/>
# <Code value="Turbidity, hellige" providers="NWIS"/>

library(dataRetrieval)
library(yaml)

cleanUp <- function(charName) {
  charName <- gsub("[^A-Za-z0-9]", " ", charName)
  return(charName)
}

config = yaml.load_file("config.yml")
states <- config$states

charName <- c("Turbidity, hellige", "Turbidity severity (choice list)", "Turbidity severity", "Turbidity")

for (i in 1:length(states)) {
  
  for (j in 1:length(charName)) {
    tryCatch({
      retrievedData <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName=charName[j], siteType="Lake, Reservoir, Impoundment")
      if (length(retrievedData)>0) { 
        write.csv(retrievedData, file = paste0(cleanUp(charName[j]),states[[i]]$fips,".csv"),row.names=FALSE)
      } 
    },error = function(e){})
    
  }
  
} 

