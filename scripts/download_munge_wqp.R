
download_merge_wqp <- function(wqp_status){
  
  sb_id <- id_from_status(wqp_status)
  files = item_file_download(sb_id, dest_dir=tempdir(), overwrite_file = TRUE)
  
  return(merge_files(files))
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