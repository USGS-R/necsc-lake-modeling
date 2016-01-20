library(geoknife)
library(yaml)

load_nldas_config <- function(){
  yaml.load_file("configs/nldas_config.yml")
}


lake_summary_nldas <- function(project_lake_locations, config){
  
  knife = webprocess(url=config$wps_url)
  
  fabric = webdata(url=config$data_url, variable=config$variables, times=config$times)
  
  # here we should check what files already exist and pare down the requests to be shaped
  
  job <- geoknife(stencil=project_lake_locations, fabric, knife, wait=TRUE)
  if (successful(job)){
    data = result(job, with.units=TRUE)
    features = head(names(data)[-1],-3)
    cat(paste(features,collapse='\t'), file='data/nldas_lakes.txt', append = FALSE)
  } else {
    message(check(job)$status)
  }

}