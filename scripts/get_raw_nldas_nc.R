library(geoknife)


create_nldas_ncml <- function(nldas_config, file='data/NLDAS_sub/nldas_miwimn.ncml'){
  
  ncml <- newXMLNode('netcdf', namespace=c(xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2"))
  agg <- newXMLNode('aggregation', parent = ncml, attrs = c(type="union"))
  vars <- nldas_config$sub_variables
  for (var in vars){
    nc <- newXMLNode('netcdf', parent = agg)
    join <- newXMLNode('aggregation', parent = nc, attrs=c(type="joinExisting", dimName="time"))
    newXMLNode('scan', parent = join, attrs=c(location=".", suffix=sprintf("_%s.nc",var)))
  }
  saveXML(ncml, file = file)
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
  cat(sprintf('\n%s files are on the server but are no longer used and can be removed...',length(rm.files)), file=mssg.file, append = TRUE)
  ._d <- sapply(sprintf('remove: %s',rm.files), message)
  rm(._d)
  
  write_grid <- function(x){
    v <- strsplit(x,'[.]')[[1]]
    sprintf("[%s:1:%s]",v[1],v[2])
  }
  
    
  for (file in new.files){
    
    cat(sprintf('\n** transferring %s to thredds server...',file), file=mssg.file, append = TRUE)
    
    file.chunks <- strsplit(file,'[_]')[[1]]
    lat.i = write_grid(file.chunks[3])
    lon.i = write_grid(file.chunks[4])
    time.i = write_grid(file.chunks[2])
    var = strsplit(file.chunks[5],'[.]')[[1]][1]
    url <- sprintf('%s?lon%s,time%s,lat%s,%s%s%s%s', nldas_config$nldas_url, lon.i, time.i, lat.i, var, time.i, lat.i, lon.i)
    # to tempfolder...
    # // output <- system(sprintf("nccopy -m 15m %s %s", url, local.nc.file))
    output = F
    if (!output){
      #rsync, and verify that is good
      
      cat('done! **', file=mssg.file, append = TRUE)
    } else {
      cat(url, ' FAILED **', file=mssg.file, append = TRUE)
    }
    
    # //unlink(local.nc.file)
    
    
  }

}

