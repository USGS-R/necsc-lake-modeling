
download_merge_wqp <- function(wqp_status){
  
  variable <- strsplit(wqp_status,'[/]')[[1]][2]
  sb_id <- id_from_status(wqp_status)
  #file.names <- 
  scratch_dir = paste0('data/WQP_scratch_folder/', var)
  
  files = Sys.glob(paste0(scratch_dir, '/*.rds')) #item_file_download(sb_id, dest_dir=tempdir(), overwrite_file = TRUE)
  message('downloaded ',length(files),' files')

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
    filter(!is.na(secchi)) %>% 
    select(Date, wqx.id, secchi)
}

munge_temperature <- function(data.in){
  
  max.temp <- 40 # threshold!
  min.temp <- 0
  max.depth <- 260
  
  depth.unit.map <- data.frame(depth.units=c('meters','m','in','ft','feet','cm', 'mm', NA), 
                         depth.convert = c(1,1,0.0254,0.3048,0.3048,0.01, 0.001, NA), 
                         stringsAsFactors = FALSE)
  
  unit.map <- data.frame(units=c("deg C","deg F", NA), 
                         convert = c(1, 1/1.8,NA), 
                         offset = c(0,-32,NA),
                         stringsAsFactors = FALSE)
  
  activity.sites <- group_by(data.in, OrganizationIdentifier) %>% 
    summarize(act.n = sum(!is.na(ActivityDepthHeightMeasure.MeasureValue)), res.n=sum(!is.na((ResultDepthHeightMeasure.MeasureValue)))) %>% 
    mutate(use.depth.code = ifelse(act.n>res.n, 'act','res')) %>% 
    select(OrganizationIdentifier, use.depth.code)
  
  left_join(data.in, activity.sites, by='OrganizationIdentifier') %>% 
    mutate(raw.depth = as.numeric(ifelse(use.depth.code == 'act', ActivityDepthHeightMeasure.MeasureValue, ResultDepthHeightMeasure.MeasureValue)),
           depth.units = ifelse(use.depth.code == 'act', ActivityDepthHeightMeasure.MeasureUnitCode, ResultDepthHeightMeasure.MeasureUnitCode)) %>% 
    rename(Date=ActivityStartDate, raw.value=ResultMeasureValue, units=ResultMeasure.MeasureUnitCode, wqx.id=MonitoringLocationIdentifier) %>% 
    select(Date, raw.value, units, raw.depth, depth.units, wqx.id) %>% 
    left_join(unit.map, by='units') %>% 
    left_join(depth.unit.map, by='depth.units') %>% 
    mutate(wtemp=convert*(raw.value+offset), depth=raw.depth*depth.convert) %>% 
    filter(!is.na(wtemp), !is.na(depth), wtemp <= max.temp, wtemp >= min.temp, depth <= max.depth) %>% 
    select(Date, wqx.id, depth, wtemp)
}


munge_wqp <- function(data.file){
  variable <- strsplit(strsplit(data.file,'[/]')[[1]][2],'[_]')[[1]][1]
  return(do.call(paste0('munge_',variable), list(data.in = readRDS(data.file))))
}


map_wqp <- function(munged.wqp, wqp.nhd.lookup, mapped.file){
  mapped.wqp <- left_join(munged.wqp, rename(wqp.nhd.lookup, wqx.id=MonitoringLocationIdentifier), by = 'wqx.id') %>% 
    select(-wqx.id, -LatitudeMeasure,-LongitudeMeasure) %>% 
    filter(!is.na(id))
  write.table(mapped.wqp, file=gzfile(mapped.file), quote = FALSE, row.names = FALSE, sep = '\t')
  
}