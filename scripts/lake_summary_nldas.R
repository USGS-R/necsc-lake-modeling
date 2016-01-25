library(geoknife)
library(yaml)

load_config <- function(data.source="configs/NLDAS_config.yml"){
  yaml.load_file(data.source)
}

lake_driver_nldas <- function(file='data/NLDAS_data/NLDAS_driver_file_list.tsv'){
  mssg.file <- 'data/NLDAS_data/NLDAS_driver_status.txt'
  files <- strsplit(readLines(file, n = -1),'\t')[[1]]
  #server.files <- nldas_server_files()
  cat('index of files contains', length(files), file=mssg.file, append = FALSE)
  
  perm.ids <- unique(sapply(strsplit(files,'[_]'),function(x)x[2]))
  
  # APPEND files? 
  
  #new.files <- setdiff(files, server.files)
  #rm.files <- setdiff(server.files, files)
  new.files <- files
  
  config <- load_config("configs/NLDAS_config.yml")
  
  cat(sprintf('\n%s files are new...',length(new.files)), file=mssg.file, append = TRUE)
  
  knife = webprocess(url=config$wps_url)
  
  fabric = webdata(url=config$data_url, variable=config$data_variables, times=config$data_times)
  
  # here we should check what files already exist and pare down the requests to be shaped
  
  job <- geoknife(stencil=stencil_from_id(perm.ids), fabric, knife, wait=TRUE)
  if (successful(job)){
    data = result(job, with.units=TRUE)
    features = head(names(data)[-1],-3)
    cat(paste(features,collapse='\t'), file='data/nldas_lakes.txt', append = FALSE)
  } else {
    message(check(job)$status)
  }

}

calc_nldas_driver_files <- function(config, lake.locations){
  
  times <- config$data_times
  vars <- config$data_variables
  
  time.chunk <- paste(sapply(times, function(x) paste(strsplit(x, '[-]')[[1]],collapse='')), collapse='.')
  
  perm.files <- sprintf("NLDAS_%s_%s_", lake.locations$permID, time.chunk)
  files <- as.vector(unlist(sapply(perm.files,paste0, vars,'.RData')))
  #"NLDAS_permID_19790101.20160116_apcpsfc.RData"
  
  cat(files,'\n', file='data/NLDAS_data/NLDAS_driver_file_list.tsv', sep = '\t', append = FALSE)
}