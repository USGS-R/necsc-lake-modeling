
download_merge_wqp <- function(wqp_status){
  
  variable <- strsplit(wqp_status,'[/]')[[1]][2]
  sb_id <- id_from_status(wqp_status)
  #file.names <- 
  
  files = item_file_download(sb_id, dest_dir=tempdir(), overwrite_file = TRUE)
  message('downloaded ',length(files),' files')
  #message(length(),'were local')
  file.out <- file.path('data',variable,'local.rds')
  saveRDS(merge_files(files), file = file.out)
  return(file.out)
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

munge_secchi <- function(data.in){
  
  unit.map <- data.frame(units=c('m','in','ft','cm', NA), 
                         convert = c(1,0.0254,0.3048,0.01, NA), 
                         stringsAsFactors = FALSE)

  rename(data.in, Date=ActivityStartDate, value=ResultMeasureValue, units=ResultMeasure.MeasureUnitCode, wqx.id=MonitoringLocationIdentifier) %>% 
    select(Date, value, units, wqx.id) %>% 
    left_join(unit.map, by='units') %>% 
    mutate(secchi=value*convert) %>% 
    filter(!is.na(secchi), !units %in% unit.map$units) %>% 
    select(Date, wqx.id, secchi)
}

munge_temperature <- function(data.in){
  
  depth.unit.map <- data.frame(depth.units=c('m','in','ft','cm', 'mm', NA), 
                         depth.convert = c(1,0.0254,0.3048,0.01, 0.001, NA), 
                         stringsAsFactors = FALSE)
  
  unit.map <- data.frame(units=c("deg C","deg F", NA), 
                         convert = c(1, 1/1.8,NA), 
                         offset = c(0,-32,NA),
                         stringsAsFactors = FALSE)
  
  rename(data.in, Date=ActivityStartDate, raw.value=ResultMeasureValue, units=ResultMeasure.MeasureUnitCode, wqx.id=MonitoringLocationIdentifier,
         raw.depth=ActivityDepthHeightMeasure.MeasureValue, depth.units=ActivityDepthHeightMeasure.MeasureUnitCode) %>% 
    select(Date, raw.value, units, raw.depth, depth.units, wqx.id) %>% 
    left_join(unit.map, by='units') %>% 
    left_join(depth.unit.map, by='depth.units') %>% 
    mutate(wtemp=convert*(raw.value+offset), depth=raw.depth*depth.convert) %>% 
    filter(!is.na(wtemp), !is.na(depth)) %>% 
    select(Date, wqx.id, depth, wtemp)
}


munge_wqp <- function(data.file){
  variable <- strsplit(strsplit(data.file,'[/]')[[1]][2],'[_]')[[1]][1]
  return(do.call(paste0('munge_',variable), list(data.in = readRDS(data.file))))
}


map_wqp <- function(munged.wqp, wqp.nhd.lookup, mapped.file){
  mapped.wqp <- left_join(munged.wqp, rename(wqp.nhd.lookup, wqx.id=MonitoringLocationIdentifier), by = 'wqx.id') %>% 
    select(-wqx.id) %>% 
    filter(!is.na(id))
  write.table(mapped.wqp, file=mapped.file, quote = FALSE, row.names = FALSE, sep = '\t')
}