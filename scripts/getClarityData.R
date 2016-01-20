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

cleanUp <- function(charName) {
  charName <- gsub("[^A-Za-z0-9]", "", charName)
  return(charName)
}

config = yaml.load_file("config.yml")
states <- config$states

charName <- c("Depth, Secchi disk depth", "Depth, Secchi disk depth (choice list)","Secchi Reading Condition (choice list)","Secchi depth", "Transparency, Secchi tube with disk", "Transparency, tube with disk", "Water transparency, Secchi disc", "Water transparency, tube with disk")

secchi <- data.frame()

for (i in 1:length(states)) { 
  
  for (j in 1:length(charName)) { 
    tryCatch({ 
      retrievedData <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName=charName[j], siteType="Lake, Reservoir, Impoundment")
      if (length(retrievedData)>0) { 
        secchi <- rbind(secchi, as.data.frame(retrievedData))
      }  
    },error = function(e){}) 
    
  }
  
}
write.csv(secchi, file = "secchi.csv",row.names=FALSE)
