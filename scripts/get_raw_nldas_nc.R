
loadConfig()

opt <- options()$necsc

sync_ncml <- function(file){
  server.file <- tail(strsplit(file,'[/]')[[1]],1)
  output <- system(sprintf('rsync -rP --rsync-path="sudo -u tomcat rsync" %s %s@cida-eros-netcdfdev.er.usgs.gov:%s%s', file, opt$necsc_user, opt$thredds_dir, server.file),
                   ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (!output)
    invisible(output)
  else 
    stop(output)
}

create_nldas_ncml <- function(file='data/NLDAS_sub/NLDAS_file_list.tsv'){
  files <- strsplit(readLines(file, n = -1),'\t')[[1]]
  times <- unique(unname(sapply(files,function(x) paste(strsplit(x, '[_]')[[1]][1:4], collapse='_'))))
  vars <- unique(unname(sapply(files,function(x) paste(strsplit(tail(strsplit(x, '[_]')[[1]],1),'[.]')[[1]][1], collapse='_'))))

  ncml <- newXMLNode('netcdf', namespace=c("http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2", xlink="http://www.w3.org/1999/xlink"))
  agg <- newXMLNode('aggregation', parent = ncml, attrs = c(type="union"))
  for (var in vars){
    join <- newXMLNode('aggregation', parent = agg, attrs=c(type="joinExisting", dimName="time"))
    for (t in times){
      newXMLNode('netcdf', parent = join, attrs=c(location=sprintf("%s_%s.nc", t, var)))
    }
    
  }
  saveXML(ncml, file = 'data/NLDAS_sub/nldas_miwimn.ncml')
}

calc_nldas_files <- function(nldas_config, nhd_config){
  # mock up huge request in order to get the nccopy response as an exception from GDP:
  datasetURI <- nldas_config$nldas_url
  vars <- nldas_config$sub_variables
  times <- nldas_config$sub_times
  
  states <- sapply(nhd_config$states, function(x) x$name)
  stencil <- webgeom(paste0('state::',paste(states,collapse=',')))
  fabric <- webdata(url=datasetURI, variables=vars, times=times)
  knife <- webprocess(url = nldas_config$wps_url, algorithm=list(`OPeNDAP Subset`="gov.usgs.cida.gdp.wps.algorithm.FeatureCoverageOPeNDAPIntersectionAlgorithm"), OUTPUT_TYPE="netcdf")
  job <- geoknife(stencil, fabric, knife = knife, wait=TRUE)
  grid.data <- strsplit(check(job)$status,'[,?]')[[1]][-1]
  get_grid <- function(data){
    strsplit(strsplit(strsplit(data,'[[]')[[1]][2],'[]]')[[1]],'[:]')[[1]][-2]
  }
  
  lon <- get_grid(grid.data[1])
  time <- get_grid(grid.data[2])
  lat <- get_grid(grid.data[3])
  grids <- data.frame(lon=lon,lat=lat,time=time, stringsAsFactors = FALSE)
  start.i <- seq(as.numeric(grids$time[1]),to = as.numeric(grids$time[2]), by = nldas_config$sub_split)
  end.i <- c(tail(start.i-1,-1), as.numeric(grids$time[2]))
  
  # creates file string: "NLDAS_291000.291999_132.196_221.344_"
  time.files <- sprintf(paste0(sprintf("NLDAS_%i.%i",start.i,end.i),'_%s.%s_%s.%s_'), lat[1], lat[2], lon[1], lon[2])
  files <- as.vector(unlist(sapply(time.files,paste0, vars,'.nc')))
  
  cat(files,'\n', file='data/NLDAS_sub/NLDAS_file_list.tsv', sep = '\t', append = FALSE)
}

## use rsync dry run to get a list of what the dry run found for the file list, and what shouldn't be there.
nldas_server_files <- function(){
  config <- load_config("configs/NLDAS_config.yml")
  server.data <- xmlParse(config$catalog_url, useInternalNodes = T)
  
  nsDefs <- xmlNamespaceDefinitions(server.data )
  ns <- structure(sapply(nsDefs, function(x) x$uri), names = names(nsDefs))
  names(ns)[1] <- "xmlns"
  ncdf.datasets <- getNodeSet(server.data,'/xmlns:catalog/xmlns:dataset/xmlns:dataset[substring(@name, string-length(@name) - string-length(".nc") +1) = ".nc"]', ns)
  ncdf.files <- unlist(xmlApply(ncdf.datasets, function(x) xmlAttrs(x)[['name']]))
  return(ncdf.files)
}

nccopy_nldas <- function(file='data/NLDAS_sub/NLDAS_file_list.tsv'){
  
  mssg.file <- 'data/NLDAS_sub/NLDAS_sub_status.txt'
  files <- strsplit(readLines(file, n = -1),'\t')[[1]]
  server.files <- nldas_server_files()
  cat('index of files contains', length(files), file=mssg.file, append = FALSE)
  
  new.files <- setdiff(files, server.files)
  rm.files <- setdiff(server.files, files)
  
  cat(sprintf('\n%s files are new...',length(new.files)), file=mssg.file, append = TRUE)
  # if files are on the server and won't be used, STOP!!
  if (length(rm.files) > 0){
    cat(sprintf('\n%s files are on the server but are no longer used and can be removed...',length(rm.files)), file=mssg.file, append = TRUE)
    message(sprintf('remove: %s',paste(paste0(opt$thredds_dir,rm.files), collapse=' ')))
    stop(sprintf('\n%s files are on the server but are no longer used and can be removed...',length(rm.files)))
  }
  
  write_grid <- function(x){
    v <- strsplit(x,'[.]')[[1]]
    sprintf("[%s:1:%s]",v[1],v[2])
  }
    
  nldas_config <- load_config("configs/NLDAS_config.yml")
  
  registerDoMC(cores=4)
  
  foreach(file=new.files) %dopar% {
      
    local.nc.file <- file.path(tempdir(), file)
    
    
    file.chunks <- strsplit(file,'[_]')[[1]]
    lat.i = write_grid(file.chunks[3])
    lon.i = write_grid(file.chunks[4])
    time.i = write_grid(file.chunks[2])
    var = strsplit(file.chunks[5],'[.]')[[1]][1]
    
    url <- sprintf('http%s?lon%s,time%s,lat%s,%s%s%s%s', substr(nldas_config$nldas_url, 5, stop = nchar(nldas_config$nldas_url)), lon.i, time.i, lat.i, var, time.i, lat.i, lon.i)
    
    # to tempfolder...
    output <- system(sprintf("nccopy -m 15m %s %s", url, local.nc.file))
    cat(sprintf('\n** nccopy %s%s to %s...', var, time.i, local.nc.file), file=mssg.file, append = TRUE)
    if (!output){
      cat('done! **', file=mssg.file, append = TRUE)
      
      output <- system(sprintf('rsync -rP --rsync-path="sudo -u tomcat rsync" %s %s@cida-eros-netcdfdev.er.usgs.gov:%s%s', local.nc.file, opt$necsc_user, opt$thredds_dir, file),
                       ignore.stdout = TRUE, ignore.stderr = TRUE)
      cat('\n** transferring file to thredds server...', file=mssg.file, append = TRUE)
      #rsync, and verify that is good
      if (!output){
        cat('done! **', file=mssg.file, append = TRUE)
        message('rsync of ',file, ' complete! ', Sys.time())
      } else {
        cat(url, ' FAILED **', file=mssg.file, append = TRUE)
      }
      
    } else {
      cat(url, ' FAILED **', file=mssg.file, append = TRUE)
    }
    
    unlink(local.nc.file)
    
    
  }

}

