library(dataRetrieval)
library(yaml)

#read in configs
nhd_config = yaml.load_file("configs/NHD_config.yml")
wqp_config = yaml.load_file("configs/wqp_config.yml")

#get some of the vars we need
states <- nhd_config$states

vars <- wqp_config$variables
for (v in 1:length(vars)) {
  varList <- unlist(vars)
}

startDate <- as.Date(wqp_config$startDate)
endDate <- as.Date(wqp_config$endDate)
firstYear <- as.numeric(format(startDate, format = "%Y"))
lastYear <- as.numeric(format(endDate, format= "%Y"))
numYears <- as.numeric(lastYear-firstYear)

siteType <- wqp_config$siteType

#build file list we expect based on configs
fileList <- list()
for (j in 1:length(varList)) {
  for (i in 0:length(numYears)) {
    for (k in 1:length(states)) {
      print(paste0(varList[j],"_",states[[k]]$fips,"_",firstYear+i))
    }
  }
}
cat(fileList, file="fileNames.txt", append=FALSE)