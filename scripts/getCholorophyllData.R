# Trying all these values from WQP http://www.waterqualitydata.us/Codes/Characteristicname?mimeType=xml
# <Code value="Chlorophyll" providers="NWIS STEWARDS STORET"/>
# <Code value="Chlorophyll A" providers="STEWARDS"/>
# <Code value="Chlorophyll a" providers="NWIS STORET"/>
# <Code value="Chlorophyll a (probe relative fluorescence)" providers="STORET"/>
# <Code value="Chlorophyll a (probe)" providers="STORET"/>
# <Code value="Chlorophyll a - Periphyton (attached)" providers="STORET"/>
# <Code value="Chlorophyll a - Phytoplankton (suspended)" providers="STORET"/>
# <Code value="Chlorophyll a, corrected for pheophytin" providers="STORET"/>
# <Code value="Chlorophyll a, free of pheophytin" providers="STORET"/>
# <Code value="Chlorophyll a, uncorrected for pheophytin" providers="STORET"/>
# <Code value="Chlorophyll b" providers="NWIS STORET"/>
# <Code value="Chlorophyll c" providers="NWIS STORET"/>
# <Code value="Chlorophyll/Pheophytin ratio" providers="STORET"/>

# uses the config.yml file to generate a list of states and grab the data using dataRetrieval calls

library(dataRetrieval)
library(yaml)

cleanUp <- function(charName) {
  charName <- gsub("[^A-Za-z0-9]", " ", charName)
  return(charName)
}

config = yaml.load_file("config.yml")
states <- config$states

charName <- c("Chlorophyll", "Chlorophyll A", "Chlorophyll a","Chlorophyll a (probe relative fluorescence)","Chlorophyll a (probe)","Chlorophyll a - Periphyton (attached)", "Chlorophyll a - Phytoplankton (suspended)", "Chlorophyll a, corrected for pheophytin", "Chlorophyll a, free of pheophytin", "Chlorophyll a, uncorrected for pheophytin", "Chlorophyll b", "Chlorophyll c", "Chlorophyll/Pheophytin ratio")

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
  