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
  
  cat(files, file='data/NLDAS_sub/NLDAS_file_list.tsv', sep = '\t', append = FALSE)
}

nccopy_nldas <- function(file='data/NLDAS_sub/NLDAS_file_list.tsv'){
  nc.message <- 'copying files from NLDAS to...'
  cat(nc.message, file='data/NLDAS_sub/NLDAS_sub_status.txt', append = FALSE)
#   years <- seq(1979,length.out = length(start.i)) # start year is hardcoded!
#   
#   lat.i <- sprintf('[%s:1:%s]', grids$lat[1], grids$lat[2])
#   lon.i <- sprintf('[%s:1:%s]', grids$lon[1], grids$lon[2])
#   
#   temp.dir <- tempdir()
#   for (i in 1:length(years)){
#     year <- years[i]
#     message('working in ',temp.dir,' for ',year)
#     for (var in vars){
#       time.i <- sprintf('[%s:1:%s]', start.i[i], end.i[i])
#       
#       url <- sprintf('%s?lon%s,time%s,lat%s,%s%s%s%s', nldas_config$nldas_url, lon.i, lat.i, time.i, var, time.i, lat.i, lon.i)
#       # use 15m option for triple the buffer size  [-m n] memory buffer size (default 5 Mbytes)
#       file.name <- sprintf('%s/NLDAS_%s_%s.nc',temp.dir, year, var)
#       if(file.exists(sprintf('/Volumes/Seagate Backup Plus Drive/data/NLDAS/%s.gz',basename(file.name)))){
#         message('****\nSKIPPING ',var,'\nfor ',year,', file exists\n****')
#       } else{
#         output <- system(sprintf("nccopy -m 15m %s %s", url, file.name))
#         if (!output){
#           zipped.file <- R.utils::gzip(filename=file.name)
#           file.copy(from = zipped.file[1],  to = sprintf('/Volumes/Seagate Backup Plus Drive/data/NLDAS/%s', basename(zipped.file[1])))
#           unlink(zipped.file[1])
#           message(Sys.time())
#           message('****\ndone with ',var,'\nfor ',year,'\n****')
#         } else {
#           message(output)
#           message('****\nFAILED ',var,'\nfor ',year,'\n****')
#         }
#       }
#     }
#   }
}

