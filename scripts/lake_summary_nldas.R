library(geoknife)
library(yaml)

load_config <- function(data.source){
  yaml.load_file(data.source)
}

sync_driver_index <- function(local.file){
  file = 'driver_index.tsv'
  data.source <- strsplit(local.file,'[/_]')[[1]][2]
  output <- system(sprintf('rsync -rP %s %s@cidasdpdfsuser.cr.usgs.gov:%s%s', local.file, opt$necsc_user, paste0(opt$driver_dir,sprintf('drivers_GLM_%s/',data.source)), file),
                   ignore.stdout = TRUE, ignore.stderr = TRUE)
  return(output)
}

driver_server_files <- function(status.file, write.file=TRUE){
  
  data.source <- strsplit(strsplit(status.file,'[/]')[[1]][2],'[_]')[[1]][1]
  output <- system(sprintf('ssh %s@cidasdpdfsuser.cr.usgs.gov ls %s',opt$necsc_user, paste0(opt$driver_dir,sprintf('drivers_GLM_%s/', data.source))), intern = TRUE, ignore.stderr = TRUE)
  
  file.list <- output[grepl(paste0(data.source, '_'), output)]
  if (write.file){
    time.start <- parse_driver_file_name(file.list, 'time.start', unique.vals=FALSE)
    time.start <- unname(sapply(time.start, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8))))
    
    time.end <- parse_driver_file_name(file.list, 'time.end', unique.vals=FALSE)
    time.end <- unname(sapply(time.end, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8))))
    
    file.index <- data.frame('id' = parse_driver_file_name(file.list, 'ids', unique.vals=FALSE), 
                             'time.start' = time.start,
                             'time.end' = time.end,
                             'variable' = parse_driver_file_name(file.list, 'vars', unique.vals=FALSE),
                             'file.name' = file.list, stringsAsFactors = FALSE)
    
    file.index <- file.index[sort.int(file.index$id, index.return=TRUE)$ix, ]
    write.table(file.index, file = sprintf('data/%s_summ/%s_driver_index.tsv', data.source, data.source), sep = '\t', row.names = FALSE)
  } else {
    return(file.list)
  }
}

parse_driver_file_name <- function(files, param, unique.vals=TRUE){
  values = switch(param,
                  ids = paste(sapply(strsplit(files,'[_]'),function(x)x[2]),sapply(strsplit(files,'[_]'),function(x)x[3]), sep='_'),
                  vars = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[5]),function(x) strsplit(x,'[.]')[[1]][1])),
                  time.start = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[4]),function(x) strsplit(x,'[.]')[[1]][1])),
                  time.end = unname(sapply(sapply(strsplit(files,'[_]'),function(x)x[4]),function(x) strsplit(x,'[.]')[[1]][2])))
  if (unique.vals)
    values <- unique(values)
  return(values)
}

lake_files_with_var <- function(files, var){
  files[grepl(var, files)]
}

lake_driver_nldas <- function(file='data/NLDAS_data/NLDAS_driver_file_list.tsv'){
  data.source <- strsplit(file,'[/_]')[[1]][2]
  config <- load_config(sprintf("configs/%s_config.yml",data.source))
  
  mssg.file <- sprintf('data/%s_data/%s_driver_status.txt',data.source,data.source)
  files <- strsplit(readLines(file, n = -1),'\t')[[1]]
  server.files <- driver_server_files(mssg.file, write.file=FALSE)
  cat('index of files contains', length(files), file=mssg.file, append = FALSE)
  
  
  # APPEND files? no, initially this will build files clean. Later we can add append. 
  
  
  new.files <- setdiff(files, server.files)
  rm.files <- setdiff(server.files, files)
  if (length(new.files) == 0){
    message('no new files to sync. doing nothing')
    return()
  }

  
  knife = webprocess(url=config$wps_url)
  temp.dir <- tempdir()
  
  vars <- sort(parse_driver_file_name(new.files, 'vars'))
  
  cat('\n', length(new.files),' are new for ', length(vars), ' variables...', file=mssg.file, append = TRUE)  
  
  job <- geojob() # empty job
  
  for (var in vars){
    post.files <- lake_files_with_var(new.files, var)
    times <- c()
    times[1] <- parse_driver_file_name(post.files, 'time.start') # will error if length > 1
    times[2] <- parse_driver_file_name(post.files, 'time.end')
    times <- unname(sapply(times, function(x) paste0(substr(x,1,4),'-',substr(x,5,6),'-',substr(x,7,8), ' UTC')))
    ids <- parse_driver_file_name(post.files, 'ids')
    cat(sprintf('\n%s files are new for variable %s...',length(post.files), var), file=mssg.file, append = TRUE)
    groups.s <- seq(1,length(ids), config$driver_split)
    groups.e <- c(tail(groups.s-1,-1L),length(ids))
    
    data_variable <- config$data_variables[config$variable_names == var]
    fabric = webdata(url=config$data_url, variables=data_variable, times=times)
    
    for (i in 1:(length(groups.s)+1)){
      
      # start a new job, don't wait for it. 
      if (i != (length(groups.s)+1)){
        lake.ids <- ids[groups.s[i]:groups.e[i]]
        cat('\nbegin job for ',length(lake.ids),' features, and variable:',var, '...', file=mssg.file, append = TRUE)
        new.job <- geoknife(stencil=stencil_from_id(lake.ids), fabric, knife, wait=FALSE, sleep.time=60)
      }
        
      
      # do all the clean up work while the other job runs
      if (successful(job)){
        message(job@id,' completed')
        cat('success! ...downloading... ', file=mssg.file, append = TRUE)
        data = tryCatch({
          result(job, with.units=TRUE)
        }, error = function(e) {
          message(job@id,' failed to download')
          cat('** job FAILED to download **\n',job@id, file=mssg.file, append = TRUE)
          return(NULL)
        })
        
        if (!is.null(data)){
          bad.file = FALSE
          if ('time(day of year)' %in% names(data)){
            data <- reform_notaro(data) #hack for non-CF data from Notaro
          }
          dr <- format(c(head(data$DateTime,1), tail(data$DateTime,1)), '%Y-%m-%d UTC', tz = 'UTC')
          if (dr[1] != times[1] | dr[2] != times[2]){
            message('file date range does not match! failure!', length(data$DateTime),'timesteps found')
            cat(' is incomplete **', file=mssg.file, append = TRUE)
            message('re-trying download')
            bad.file = TRUE
            data = tryCatch({
              result(job, with.units=TRUE)
            }, error = function(e) {
              message(job@id,' failed to download')
              cat('** job FAILED to download **\n',job@id, file=mssg.file, append = TRUE)
              return(NULL)
            })
            if (!is.null(data)){
              dr <- format(c(head(data$DateTime,1), tail(data$DateTime,1)), '%Y-%m-%d UTC', tz = 'UTC')
              if (dr[1] != times[1] | dr[2] != times[2]){
                message('file date range does not match! failure!', length(data$DateTime),'timesteps found')
                cat(' is incomplete **', file=mssg.file, append = TRUE)
              } else {
                bad.file = FALSE
              }
              # else {is still a bad.file}
            } 
          } 
          if (!bad.file){
            cat('success!', file=mssg.file, append = TRUE)
            for (file in parse.files){
              
              tryCatch({
                chunks <- strsplit(file, '[_]')[[1]]
                perm.id <- paste(chunks[2:3],collapse='_')
                var <- strsplit(chunks[5],'[.]')[[1]][1]
                data.site <- data[c('DateTime', perm.id,'variable')] %>% 
                  filter(variable == data_variable) %>% 
                  select_('DateTime',2)
                # can end up with an empty file here...
                names(data.site) <- c('DateTime', var)
                local.file <- file.path(temp.dir, file)
                
                save(data.site, file=local.file, compress="xz")
                output <- system(sprintf('rsync -rP %s %s@cidasdpdfsuser.cr.usgs.gov:%s%s', local.file, opt$necsc_user, paste0(opt$driver_dir,sprintf('drivers_GLM_%s/', data.source)), file),
                                 ignore.stdout = TRUE, ignore.stderr = TRUE)
                unlink(local.file)
                if (!output){
                  message('rsync of ',file, ' complete! ', Sys.time())
                } else {
                  cat('rsync of ', file, ' FAILED **', file=mssg.file, append = TRUE)
                }
                
              }, error = function(e){
                cat('rsync of ', file, ' FAILED **', file=mssg.file, append = TRUE)
              })
            } 
          }
        }
      } else {
        message(job@id,' failed ' )
        cat('\n** job FAILED in processing **\n', job@id, file=mssg.file, append = TRUE)
      }
      job <- wait(new.job) # now wait on the new job
      if (i != (length(groups.s)+1))
        parse.files <- post.files[groups.s[i]:groups.e[i]] #what about when i == length(groups.s)????
    }
  }
}

reform_notaro <- function(data.in){
  # get year
  data.in$times = data.in[['time(day of year)']]
  data.in[['time(day of year)']] <- NULL
  fix_date <- function(DateTime,time){
    lubridate::round_date(DateTime, unit = 'year')+time*86400
  }
  mutate(data.in, DateTime=fix_date(DateTime, times)) %>% 
    select(-times)
}

# lake.locations should now come in as 'id', with 'nhd_2637312' for example
calc_nldas_driver_files <- function(config, lake.locations){
  
  data.name <- config$data_name
  data.dir <- sprintf('data/%s_data/', data.name)
  if (!dir.exists(data.dir))
    dir.create(data.dir)
  times <- config$data_times
  vars <- config$variable_names
  
  time.chunk <- paste(sapply(times, function(x) paste(strsplit(x, '[-]')[[1]],collapse='')), collapse='.')
  
  perm.files <- sprintf("%s_%s_%s_", data.name, lake.locations$id, time.chunk)
  files <- as.vector(unlist(sapply(perm.files,paste0, vars,'.RData')))
  #"NLDAS_permID_19790101.20160116_apcpsfc.RData"
  
  cat(files,'\n', file=sprintf('%s%s_driver_file_list.tsv', data.dir, data.name), sep = '\t', append = FALSE)
}