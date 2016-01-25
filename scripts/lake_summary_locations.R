#' this returns the lake locations as a geom that can be used by geoknife. 
#' Can be a WFS or a dataframe wrapped in a simplegeom
#' 
#' 
lake_summary_locations <- function(){
  
  # --- PLACEHOLDER!!!
  warning('placeholder code')
  return(data.frame(permID=c('perm.1','perm.23'), lat=c(42.3,45.6), lon=c(-89.1,-93.1)))
  #return(simplegeom(data.frame(point1=c(-89.1,43.2), point2=c(-93.1, 45.1))))
}

stencil_from_id <- function(permIDs){
  
  # --- PLACEHOLDER!!!
  warning('placeholder code')
  simplegeom(data.frame('perm.1'=c(-89.1,43.2), 'perm.23'=c(-93.1, 45.1)))
}