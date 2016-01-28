library(geoknife)
library(yaml)

load_config <- function(data.source="configs/NLDAS_config.yml"){
  yaml.load_file(data.source)
}

sync_driver_index <- function(local.file){
  file = 'driver_index.tsv'
  output <- system(sprintf('rsync -rP %s %s@cidasdpdfsuser.cr.usgs.gov:%s%s', local.file, opt$necsc_user, opt$driver_dir, file),
                   ignore.stdout = TRUE, ignore.stderr = TRUE)
  return(output)
}

driver_server_files <- function(data.source='NLDAS', write.file=TRUE){
  output <- system(sprintf('ssh %s@cidasdpdfsuser.cr.usgs.gov ls %s',opt$necsc_user, opt$driver_dir), intern = TRUE, ignore.stderr = TRUE)
  
  file.list <- output[grepl(paste0(data.source, '_'), output)]
  if (write.file){
    time.start <- parse_driver_file_name(file.list, 'time.start', unique.vals=FALSE)
    time.start <- unname(sapply(time.start, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8))))
    
    time.end <- parse_driver_file_name(file.list, 'time.end', unique.vals=FALSE)
    time.end <- unname(sapply(time.end, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8))))
    
    file.index <- data.frame('permID' = parse_driver_file_name(file.list, 'perm.ids', unique.vals=FALSE), 
                             'time.start' = time.start,
                             'time.end' = time.end,
                             'variable' = parse_driver_file_name(file.list, 'vars', unique.vals=FALSE),
                             'file.name' = file.list)
    
    write.table(file.index, file = 'data/NLDAS_summ/NLDAS_driver_index.tsv', sep = '\t', row.names = FALSE)
  } else {
    return(file.list)
  }
}

parse_driver_file_name <- function(files, param, unique.vals=TRUE){
  values = switch(param,
         perm.ids = sapply(strsplit(files,'[_]'),function(x)x[2]),
         vars = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[4]),function(x) strsplit(x,'[.]')[[1]][1])),
         time.start = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[3]),function(x) strsplit(x,'[.]')[[1]][1])),
         time.end = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[3]),function(x) strsplit(x,'[.]')[[1]][2])))
  if (unique.vals)
    values <- unique(values)
  return(values)
}

lake_driver_nldas <- function(file='data/NLDAS_data/NLDAS_driver_file_list.tsv'){
  mssg.file <- 'data/NLDAS_data/NLDAS_driver_status.txt'
  files <- strsplit(readLines(file, n = -1),'\t')[[1]]
  server.files <- driver_server_files(data.source='NLDAS', write.file=FALSE)
  cat('index of files contains', length(files), file=mssg.file, append = FALSE)
  
  
  
  # APPEND files? no, initially this will build files clean. Later we can add append. 
  
  new.files <- setdiff(files, server.files)
  rm.files <- setdiff(server.files, files)
  if (length(new.files) == 0){
    message('no new files to sync. doing nothing')
    return()
  }
    
  
  perm.ids <- parse_driver_file_name(new.files, 'perm.ids')
  vars <- parse_driver_file_name(new.files, 'vars')
  times <- unname(lapply(unique(sapply(strsplit(new.files,'[_]'),function(x)x[3])),function(x) strsplit(x,'[.]')[[1]]))
  if (length(times) > 1)
    stop('non-unique time values', times)
  times <- times[[1]]
  times <- unname(sapply(times, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8), ' UTC')))
  
  config <- load_config("configs/NLDAS_config.yml")
  
  cat(sprintf('\n%s files are new...',length(new.files)), file=mssg.file, append = TRUE)
  stop(new.files)
  knife = webprocess(url=config$wps_url)
  temp.dir <- tempdir()
  for (var in vars){
    fabric = webdata(url=config$data_url, variables=var, times=times)
    
    # here we should check what files already exist and pare down the requests to be shaped
    
    job <- geoknife(stencil=stencil_from_id(perm.ids), fabric, knife, wait=TRUE)
    if (successful(job)){
      data = result(job, with.units=TRUE)
      for (file in new.files){
        chunks <- strsplit(file, '[_]')[[1]]
        perm.id <- chunks[2]
        var <- strsplit(chunks[4],'[.]')[[1]][1]
        data.site <- data[c('DateTime', perm.id,'variable')] %>% 
          filter(variable == var) %>% 
          select_('DateTime',2)
        names(data.site) <- c('DateTime', var)
        local.file <- file.path(temp.dir, file)
        save(data.site, file=local.file, compress="xz")
        output <- system(sprintf('rsync -rP %s %s@cidasdpdfsuser.cr.usgs.gov:%s%s', local.file, opt$necsc_user, opt$driver_dir, file),
                         ignore.stdout = TRUE, ignore.stderr = TRUE)
        cat('\n** transferring file to driver server...', file=mssg.file, append = TRUE)
        unlink(local.file)
        if (!output){
          cat('done! **', file=mssg.file, append = TRUE)
          message('rsync of ',file, ' complete! ', Sys.time())
        } else {
          cat(url, ' FAILED **', file=mssg.file, append = TRUE)
        }
        cat('\n', file,'**posted', file=mssg.file, append = TRUE)
      }
    } else {
      message(check(job)$status)
      cat('\n', fabric,'**failed', file=mssg.file, append = TRUE)
      cat('\n', check(job)$status, file=mssg.file, append = TRUE)
    }
    
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