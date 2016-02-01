#' this returns the lake locations as a geom that can be used by geoknife. 
#' Can be a WFS or a dataframe wrapped in a simplegeom
#' 
#' 
lake_summary_locations <- function(){
  
  sites <- read.csv('data/depth_data/depth_lagos_summary.csv', stringsAsFactors = FALSE)
  
  return(sites[c('permID')])
  
  
}

stencil_from_id <- function(permIDs){
  
  sites <- read.csv('data/NHD_summ/nhd_centroids.csv', stringsAsFactors = FALSE)
  for (i in 1:length(permIDs)){
    site <- sites[sites$permID == permIDs[i],]
    df <- data.frame(c(site$lon, site$lat))
    names(df) <- permIDs[i]
    if (i == 1)
      geom <- df
    else 
      geom <- cbind(geom, df)
  }
  simplegeom(geom)
}