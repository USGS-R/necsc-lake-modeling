data.sources <- c('IPSL','MIROC5','MRI') #'ACCESS','CNRM','GFDL',
source('scripts/load_config.R')
source('scripts/lake_summary_locations.R')
source('scripts/lake_summary_nldas.R')
library(geoknife)
library(yaml)
library(dplyr)
d = read.table('~/Desktop/missing_lakes.tsv', stringsAsFactors = FALSE)
ids <- unique(paste('nhd',unlist(lapply(d$V1, function(x) strsplit(x, '[_]')[[1]][3])), sep='_'))
for (data.source in data.sources){
  config <- load_config(sprintf("configs/%s_config.yml",data.source))
  
  knife = webprocess()#url=config$wps_url)
  
  temp.dir <- sprintf('missing_drivers/%s', data.source)
  if (!dir.exists(temp.dir)) dir.create(temp.dir)
  
  vars <- config$variable_names
  
  gconfig(retries=2)
  for (var in vars){
    times <- c(paste0(config$data_times[1],' UTC'), paste0(config$data_times[2],' UTC'))
    
    data_variable <- config$data_variables[config$variable_names == var]
    fabric = webdata(url=config$data_url, variables=data_variable, times=times)
    
    job <- geoknife(stencil=stencil_from_id(ids), fabric, knife, wait=TRUE, sleep.time=60)
    if (successful(job)){
      message(job@id,' completed')
      cat('success! ...downloading... ')
      data = tryCatch({
        result(job, with.units=TRUE)
      }, error = function(e) {
        message(job@id,' failed to download')
        cat('** job FAILED to download **\n',job@id)
        return(NULL)
      })
      if (!is.null(data)){
        if ('time(day of year)' %in% names(data)){
          data <- reform_notaro(data) #hack for non-CF data from Notaro
        }
          if (!is.null(data)){
            dr <- format(c(head(data$DateTime,1), tail(data$DateTime,1)), '%Y-%m-%d UTC', tz = 'UTC')
            if (dr[1] != times[1] | dr[2] != times[2]){
              message('file date range does not match! failure!', length(data$DateTime),'timesteps found')
            } else {
              bad.file = FALSE
            }
            # else {is still a bad.file}
          } 
      } 
    }
    for (id in ids){
      
      perm.id <- id
      data.site <- data[c('DateTime', perm.id,'variable')] %>% 
        filter(variable == data_variable) %>% 
        select_('DateTime',2)
      # can end up with an empty file here...
      names(data.site) <- c('DateTime', var)
      time.str <- paste(format(c(head(data.site$DateTime,1), tail(data.site$DateTime,1)), '%Y%m%d', tz = 'UTC'),collapse = '.')
      file <- paste0(data.source,'_',id,'_', time.str, '_', var,'.RData')
      local.file <- file.path(temp.dir, file)
      
      save(data.site, file=local.file, compress="xz")
    }
    message('done with ', var, ', GCM:', data.source)
}}
