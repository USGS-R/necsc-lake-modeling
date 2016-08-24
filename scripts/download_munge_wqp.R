
download_merge_wqp <- function(files){
  
  files = Sys.glob(paste0(scratch_dir, '/*.rds')) #item_file_download(sb_id, dest_dir=tempdir(), overwrite_file = TRUE)
  message('merging ',length(files),' files')

  return(merge_files(files))
}

merge_files <- function(files){
  data.out <- list()
  for (i in 1:length(files)){
    data.out[[i]] <- readRDS(files[i])
    cat(i, ' loading file \n')
  }
  cat('merging all these files now....\n')
  return(do.call(rbind, data.out))
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

munge_do <- function(data.in){
  
  max.depth <- 260
  
  depth.unit.map <- data.frame(depth.units=c('meters','m','in','ft','feet','cm', 'mm', NA), 
                               depth.convert = c(1,1,0.0254,0.3048,0.3048,0.01, 0.001, NA), 
                               stringsAsFactors = FALSE)
  
  unit.map <- data.frame(units=c("mg/l","ug/l", NA), 
                         convert = c(1, 1/1000,NA), 
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
    mutate(do=convert*raw.value, depth=raw.depth*depth.convert) %>% 
    filter(!is.na(do), !is.na(depth), depth <= max.depth) %>% 
    select(Date, wqx.id, depth, do)
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


munge_wqp <- function(data.table, variable){
  variable <- strsplit(variable,'[.]')[[1]][1]
  return(do.call(paste0('munge_',variable), list(data.in = data.table)))
}


map_wqp <- function(munged.wqp, wqp.nhd.lookup, mapped.file){
  mapped.wqp <- left_join(munged.wqp, rename(wqp.nhd.lookup, wqx.id=MonitoringLocationIdentifier), by = 'wqx.id') %>% 
    select(-wqx.id, -LatitudeMeasure,-LongitudeMeasure) %>% 
    filter(!is.na(id))
  write.table(mapped.wqp, file=gzfile(mapped.file), quote = FALSE, row.names = FALSE, sep = '\t')
  
}

map_join_wqp <- function(munged.wqp.1, munged.wqp.2, wqp.nhd.lookup, mapped.file){
  mapped.wqp.1 <- left_join(munged.wqp.1, rename(wqp.nhd.lookup, wqx.id=MonitoringLocationIdentifier), by = 'wqx.id') %>% 
    select(-LatitudeMeasure,-LongitudeMeasure) %>% 
    filter(!is.na(id))
  
  mapped.wqp.2 <- left_join(munged.wqp.2, rename(wqp.nhd.lookup, wqx.id=MonitoringLocationIdentifier), by = 'wqx.id') %>% 
    select(-LatitudeMeasure,-LongitudeMeasure) %>% 
    filter(!is.na(id))
  
  joined.wqp <- inner_join(mapped.doobs, mapped.temperature, by = c('wqx.id','Date', 'depth','id')) %>% 
    select(Date, id, wqx.id, everything())
  write.table(joined.wqp, file=gzfile(mapped.file), quote = FALSE, row.names = FALSE, sep = '\t')
}
