library(dataRetrieval)
library(yaml)


calc_wqp_files <- function(wqp_config, nhd_config, variable) {
  
  startDate <- as.Date(wqp_config$startDate)
  endDate <- as.Date(wqp_config$endDate)
  firstYear <- as.numeric(format(startDate, format = "%Y"))
  lastYear <- as.numeric(format(endDate, format= "%Y"))
  year.seq <- seq(startDate, endDate, by='year')
  beg.seq <- year.seq[seq(1,length(year.seq), by=wqp_config$yearSplit)] %>% 
    format("%Y%m%d") 
  end.seq <- c((beg_seq-1)[-1], endDate) %>% 
    format("%Y%m%d") 
  
  fips <- unlist(lapply(nhd_config$states, function(x) x$fips))
  
  fileList <- c()
  timeStamp <- paste(beg.seq, end.seq, sep=".")
  
  for (fip in fips) {
    files <- paste("wqp", variable, timeStamp, fip, sep="_")
    fileList <- c(fileList, paste0(files,".rds"))
  }
  return(fileList)
}

get_var_map <- function(config){
  var.map = lapply(config$variables, function(x) list(x)[[1]])
  append(var.map, wqp_config['siteType'])
}

get_char_names <- function(variable, var.map) {
  
  #this needs to return a list that is as long as the characteristcNames where each characteristic name is named characteristicName
  char.names = sapply(var.map[[variable]], list)
  names(char.names) <- rep('characteristicName', length(char.names))
  return(char.names)
}

wqp_server_files <- function(config){
  id <- config$sb_wqp_id
  return(item_list_files(sb_id = id)$fname)
}

calc_post_files <- function(wqp_config, nhd_config, variable){
  setdiff(calc_wqp_files(wqp_config, nhd_config, variable), wqp_server_files(wqp_config))
}

make_wqp_dirs <- function(vars){
  var.dir <- sprintf('data/%s_data', var)
  if (!dir.exists(var.dir))
    dir.create(var.dir)
}

getWQPdata <- function(fileList, var.map) {

  wqp_args <- lapply(fileList, parseWQPfileName)
  vars <- unique(sapply(wqp_args, function(x) x$varName))
  make_wqp_dirs(vars)
  for (i in seq_along(fileList)) {
    var <- args[['varName']]
    mssg.file <- sprintf('data/%s_data/wqp_%s_data_status.txt',var,var)
    
    args <- append(wqp_args[[i]], var.map['siteType'])
    char.names <- get_char_names(var, var.map)
    args[['varName']] <- NULL
    wqp.args <- append(args, char.names)
    message('getting data for ', fileList[i])
    cat('getting data for ', fileList[i], file=mssg.file, append = TRUE)
    wqp.data <- do.call(readWQPdata, wqp.args)
    local.file = file.path(tempdir(), fileList[i])
    saveRDS(wqp.data, file=local.file)
    message('posting to sciencebase for ', fileList[i])
    item = item_append_files(sb_id='56ea20d4e4b0f59b85d81fda', files=local.file)
    cat('...', fileList[i], ' posted to sciencebase\n', file=mssg.file, append = TRUE)
    message('\n')
    
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
