
download_merge_wqp <- function(wqp_status){
  
  variable <- strsplit(wqp_status,'[/]')[[1]][2]
  sb_id <- id_from_status(wqp_status)
  #file.names <- 
  
  files = item_file_download(sb_id, dest_dir=tempdir(), overwrite_file = TRUE)
  message('downloaded',length(files),'files')
  #message(length(),'were local')
  saveRDS(merge_files(files), file = file.path('data',variable,'local.rds'))
  return('local.rds')
}

merge_files <- function(files){
  data.out <- data.frame()
  for (file in files){
    data.out <- rbind(data.out, readRDS(file))
  }
  return(data.out)
}

id_from_status <- function(status.file){
  readLines(status.file, n=1L)
}

munge_wqp <- function(wqp.data){
  # dplyr
  
}