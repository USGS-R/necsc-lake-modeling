# uses the config.yml file to generate a list of states and grab the data using dataRetrieval calls

library(dataRetrieval)
library(yaml)

config = yaml.load_file("config.yml")
states <- config$states

charName <- c("Temperature, sample","Temperature, water")

for (i in 1:length(states)) {  
  temperature <- data.frame()
  for (j in 1:length(charName)) { 
    tryCatch({ 
      retrievedData <- readWQPdata(statecode=paste0("US:",states[[i]]$fips),characteristicName=charName[j], siteType="Lake, Reservoir, Impoundment")
      if (length(retrievedData)>0) { 
        temperature <- rbind(temperature, as.data.frame(retrievedData))
        success <- paste("\n Request success on", as.character(Sys.time()), "\t", "State:", config$states[i],"Value:",charName[j])
        cat(success, file="log.txt", append=TRUE)
      }  
    },
    error = function(e){
      error <- paste("\n Request failed:", "on", as.character(Sys.time()), "\t", "State:",config$states[i],"Value:",charName[j], e)
      cat(error, file="log.txt", append=TRUE)
    },
    warning = function(warn){
      warnLog <- paste("\n WARNING", "on", as.character(Sys.time()), "\t", "State:",config$states[i],"Value:",charName[j], warn)
      cat(warnLog, file="log.txt", append=TRUE)
    }) 
  } 
  write.csv(temperature, file = paste0("temperature",states[[i]]$fips,".csv"),row.names=FALSE)
}
