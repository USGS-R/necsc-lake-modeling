#' append files to a release item
#' 
#' @param sb.id a sciencebase id of the item
#' @param files a list of file paths to be uploaded
append_release_files <- function(sb.config, files, target_name){
  type <- strsplit(basename(target_name),'[.]')[[1]][1]
  item_replace_files(sb_id = sb.config[[type]]$sb.id, files = files, all = FALSE)
}