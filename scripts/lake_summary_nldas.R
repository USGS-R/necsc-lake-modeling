library(geoknife)
library(yaml)

config = yaml.load_file("configs/nldas_config.yml")

knife = webprocess(url='http://cida-test.er.usgs.gov/gdp/process/WebProcessingService')

lake_summary_nldas <- function(stencil, variable=config$variables, times=config$times){
  fabric = webdata(url='dods://cida-eros-netcdfdev.er.usgs.gov:8080/thredds/dodsC/thredds/nldas_miwimn/nldas_miwimn.ncml', 
                   variables=variable, times=times)
  
  job <- geoknife(stencil, fabric, knife, wait=TRUE)
  if (successful(job)){
    result(job, with.units=TRUE)
  } else {
    
  }
}