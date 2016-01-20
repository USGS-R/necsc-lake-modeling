library(geoknife)

get_nldas_grid <- function(){
  # mock up huge request in order to get the nccopy response as an exception from GDP:
  datasetURI <- 'dods://hydro1.sci.gsfc.nasa.gov/dods/NLDAS_FORA0125_H.002'
  vars <- c('dlwrfsfc','pressfc','apcpsfc','vgrd10m','ugrd10m','dswrfsfc','spfh2m','tmp2m')
  times <- c("1979-01-01 UTC", "2016-01-19 UTC")
  config <- load_nhd_config()
  states <- sapply(config$states, function(x) x$name)
  stencil <- webgeom(paste0('state::',paste(states,collapse=',')))
  fabric <- webdata(url=datasetURI, variables=vars, times=times)
  knife <- webprocess(algorithm=list(`OPeNDAP Subset`="gov.usgs.cida.gdp.wps.algorithm.FeatureCoverageOPeNDAPIntersectionAlgorithm"), OUTPUT_TYPE="netcdf")
  job <- geoknife(stencil, fabric, knife = knife, wait=TRUE)
  grid.data <- strsplit(check(job)$status,'[,?]')[[1]][-1]
  get_grid <- function(data){
    strsplit(strsplit(strsplit(data,'[[]')[[1]][2],'[]]')[[1]],'[:]')[[1]][-2]
  }
  lon <- get_grid(grid.data[1])
  time <- get_grid(grid.data[2])
  lat <- get_grid(grid.data[3])
  grids <- data.frame(lon=lon,lat=lat,time=time)
  return(grids)
}

nccopy_nldas <- function(grids){
  start.i <- seq(as.numeric(grids$time[1]),to = as.numeric(grids$time[2]), by = 8760)
  end.i <- c(tail(start.i-1,-1), as.numeric(grids$time[2]))
  years <- seq(1979,length.out = length(start.i))
  
  lat.i <- sprintf('[%s:1:%s]', grids$lat[1], grids$lat[2])
  lon.i <- sprintf('[%s:1:%s]', grids$lon[1], grids$lon[2])
  
  temp.dir <- tempdir()
  for (i in 1:length(years)){
    year <- years[i]
    message('working in ',temp.dir,' for ',year)
    for (var in vars){
      time.i <- sprintf('[%s:1:%s]', start.i[i], end.i[i])
      
      url <- sprintf('http://hydro1.sci.gsfc.nasa.gov/dods/NLDAS_FORA0125_H.002?lon%s,time%s,lat%s,%s%s%s%s', lon.i, lat.i, time.i, var, time.i, lat.i, lon.i)
      # use 15m option for triple the buffer size  [-m n] memory buffer size (default 5 Mbytes)
      file.name <- sprintf('%s/NLDAS_%s_%s.nc',temp.dir, year, var)
      if(file.exists(sprintf('/Volumes/Seagate Backup Plus Drive/data/NLDAS/%s.gz',basename(file.name)))){
        message('****\nSKIPPING ',var,'\nfor ',year,', file exists\n****')
      } else{
        output <- system(sprintf("nccopy -m 15m %s %s", url, file.name))
        if (!output){
          zipped.file <- R.utils::gzip(filename=file.name)
          file.copy(from = zipped.file[1],  to = sprintf('/Volumes/Seagate Backup Plus Drive/data/NLDAS/%s', basename(zipped.file[1])))
          unlink(zipped.file[1])
          message(Sys.time())
          message('****\ndone with ',var,'\nfor ',year,'\n****')
        } else {
          message(output)
          message('****\nFAILED ',var,'\nfor ',year,'\n****')
        }
      }
    }
  }
}

