library(dataRetrieval)
library(yaml)


calc_wqp_files <- function(wqp_config, nhd_config) {
  varNames <- names(wqp_config$variables)
  
  startDate <- as.Date(wqp_config$startDate)
  endDate <- as.Date(wqp_config$endDate)
  firstYear <- as.numeric(format(startDate, format = "%Y"))
  lastYear <- as.numeric(format(endDate, format= "%Y"))
  beg_seq <- seq(startDate, endDate, length.out=wqp_config$numberOfFiles)
  end_seq <- beg_seq-1
  end_seq <- end_seq[-1]
  end_seq <- c(head(end_seq, -1), tail(beg_seq, 1))
  beg_seq <- head(beg_seq, -1)
  beg_seq <- format(beg_seq, "%Y%m%d") 
  end_seq <- format(end_seq, "%Y%m%d")
  
  fips <- unlist(lapply(nhd_config$states, function(x) x$fips))
  
  fileList <- c()
  timeStamp <- paste(beg_seq, end_seq, sep=".")
  for (var in varNames) {
    for (fip in fips) {
      files <- paste("wqp", var, timeStamp, fip, sep="_")
      fileList <- c(fileList, paste0(files,".tsv"))
    }
  }
  return(fileList)
}

get_var_map <- function(config){
  lapply(config$variables, function(x) list(x)[[1]])
}

get_char_names <- function(variable, var.map) {
  
  #this needs to return a list that is as long as the characteristcNames where each characteristic name is named characteristicName
  char.names = sapply(var.map[[variable]], list)
  names(char.names) <- rep('characteristicName', length(char.names))
  return(char.names)
}

getWQPdata <- function(fileList, var.map) {
  
  wqp_args <- lapply(fileList, parseWQPfileName)
  for (i in seq_along(fileList)) {
    args <- wqp_args[[i]]
    char.names <- get_char_names(args[['varName']], var.map)
    args[['varName']] <- NULL
    wqp.args <- append(args, char.names)
    wqp.data <- do.call(readWQPdata, wqp.args)
    # write to file, do something with the file
  }
  
}

parseWQPfileName <- function(fileName) {
  
  fileParts <- strsplit(fileName,"[_]")[[1]]
  varName <- fileParts[2]
  timeStamp <- fileParts[3]
  fip <- strsplit(fileParts[4],"[.]")[[1]][1]
  startDateHi <- as.character(as.Date(format(strsplit(timeStamp,"[.]")[[1]][2]),"%Y%m%d"))
  startDateLo <- as.character(as.Date(format(strsplit(timeStamp,"[.]")[[1]][1]),"%Y%m%d"))
  
  return(list('startDateLo' = startDateLo, 'startDateHi' = startDateHi, 'statecode' = paste0("US:",fip), 'varName'= varName))
  
}
