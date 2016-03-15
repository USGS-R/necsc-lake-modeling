
loadConfig()

opt <- options()$necsc
library(XML)

create_notaro_ncml <- function(){
  files <- system(sprintf('ssh %s@cida-eros-netcdfdev.er.usgs.gov ls %s',opt$necsc_user, opt$notaro_dir), intern = TRUE, ignore.stderr = TRUE)
  files <- files[grepl('365d.nc', files)]

  chunks <- strsplit(files, '[_]')
  # "debias"       "windspeed"    "mri"          "mid21"        "longerdaymet" "ghcn"         "365d.nc"
  # look out for "debias_snv_tas_access_late21_longerdaymet_ghcn_365d.nc", which doesn't fit the pattern...
  get_i <- function(x, i){
    if (length(x) == 7)
      x[i]
    else if (length(x) == 8)
      x[i+1]
  }
  
  get_filename <- function(gcm, var, time, filenames=files){
    file.i <- grepl(files, pattern = gcm) & grepl(files, pattern = var) & grepl(files, pattern = time)
    filenames[file.i]
  }
  
  get_time_string <- function(time){
    time.vals <- c('late20' = '1980-01-01 00:00:00Z',
                   'mid21' = '2020-01-01 00:00:00Z',
                   'late21' = '2070-01-01 00:00:00Z')
    return(paste0('years since ', time.vals[[time]]))
  }
  vars <- unique(unlist(lapply(chunks, get_i, i=2)))
  GCMs <- unique(unlist(lapply(chunks, get_i, i=3)))
  times <- unique(unlist(lapply(chunks, get_i, i=4))) 
  # re-order ......
  times <- c('late20','mid21','late21')
  # create a ncml for each GCM
  for (gcm in GCMs){
    GCM <- toupper(gcm)
    ncml <- newXMLNode('netcdf', namespace=c("http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2", xlink="http://www.w3.org/1999/xlink", enhance="true"))
    agg <- newXMLNode('aggregation', parent = ncml, attrs = c(type="union"))
    for (var in vars){
      nc <- newXMLNode('netcdf', parent = agg)
      join <- newXMLNode('aggregation', parent = nc, attrs=c(type="joinExisting", dimName="year", timeUnitsChange="true"))
      for (t in times){
        loc <- newXMLNode('netcdf', parent = join, attrs=c(location=get_filename(gcm, var, t, filenames=files)))
        v <- newXMLNode('variable', parent = loc, attrs=c(name="year"))
        newXMLNode('attribute', parent = v, attrs=c(name="units", value=get_time_sring(t)))
      }
      v <- newXMLNode('variable', parent = nc, attrs=c(name="time"))
      newXMLNode('attribute', parent = v, attrs=c(name="units", value="day of year"))
      newXMLNode('attribute', parent = v, attrs=c(name="positive", value="up"))
    }
    
    saveXML(ncml, file = sprintf('data/%s_sub/%s_miwimn.ncml', GCM, gcm))
    
  }
}

sync_notaro_ncml <- function(file){
  server.file <- tail(strsplit(file,'[/]')[[1]],1)
  output <- system(sprintf('rsync -rP --rsync-path="sudo -u tomcat rsync" %s %s@cida-eros-netcdfdev.er.usgs.gov:%s%s', file, opt$necsc_user, opt$notaro_dir, server.file),
                   ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (!output)
    invisible(output)
  else 
    stop(output)
}