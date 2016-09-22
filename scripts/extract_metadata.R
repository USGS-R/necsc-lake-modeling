extract_spatial_metadata <- function(sp.path){

  sp <- readOGR(dirname(sp.path[1]), strsplit(basename(sp.path[1]), "\\.")[[1]][1])
  
  metadata.out <- list() %>% 
    append(get_bbox(sp)) %>% 
    append(get_states(sp)) %>% 
    append(get_feature_count(sp))
  
  return(metadata.out)
}

get_bbox <- function(sp){
  if (!grepl(pattern = 'WGS84', proj4string(sp))){
    stop('sp must be in WGS84 to calculate a valid bounding box')
  }
  bounds <- bbox(sp)
  return(list(wbbox=bounds[1,1], ebbox=bounds[1,2], 
              nbbox=bounds[2,1], sbbox=bounds[2,2]))
}

get_feature_count <- function(sp){
  feature.type = switch(class(sp),
                        "SpatialPointsDataFrame" = "Point",
                        "SpatialPolygonsDataFrame" = "G-polygon")
  list('feature-type'=feature.type, 'feature-count'=length(sp))
}

get_states <- function(sp){
  # // CONUS
  destination = tempfile(pattern = 'CONUS_States', fileext='.zip')
  query <- 'http://cida.usgs.gov/gdp/geoserver/wfs?service=WFS&request=GetFeature&typeName=derivative:CONUS_States&outputFormat=shape-zip&version=1.0.0'
  file <- GET(query, write_disk(destination, overwrite=T), progress())
  shp.path <- tempdir()
  unzip(destination, exdir = shp.path)
  states <- readOGR(shp.path, layer='CONUS_States') %>% 
    spTransform(proj4string(sp))
  overlaps <- sp_overlaps(states, sp)
  state.has.sp <- as.character(states$STATE)[colSums(overlaps) > 0]
  
  destination = tempfile(pattern = 'Alaska', fileext='.zip')
  query <- 'http://cida.usgs.gov/gdp/geoserver/wfs?service=WFS&request=GetFeature&typeName=sample:Alaska&outputFormat=shape-zip&version=1.0.0'
  file <- GET(query, write_disk(destination, overwrite=T), progress())
  shp.path <- tempdir()
  unzip(destination, exdir = shp.path)
  alaska <- readOGR(shp.path, layer='Alaska') %>% 
    spTransform(proj4string(sp)) %>% 
    gSimplify(tol=0.001)
  if (any(sp_overlaps(alaska, sp))){
    state.has.sp <- c(state.has.sp, "Alaska")
  }
  
  state.metadata <- lapply(sort(state.has.sp), function(x) list('state-name'=x, 'state-abbr' = dataRetrieval::stateCdLookup(x)))
  return(list(states=state.metadata))
}

sp_overlaps <- function(sp0, sp1){
  if (is(sp1, "SpatialPointsDataFrame")){
    gContains(sp0, sp1, byid = TRUE)
  } else { # is "SpatialPolygonsDataFrame"
    gOverlaps(sp0, gSimplify(sp1, tol=0.001), byid = TRUE)
  }
}

read_sb_shape <- function(sb.config, target_name){
  sb.id <- sb.config[[target_name]]$sb.id
  feature.name <- sb.config[[target_name]]$feature.name
  destination = tempfile(pattern = feature.name, fileext='.zip')
  query <- sprintf('https://www.sciencebase.gov/catalogMaps/mapping/ows/%s?service=wfs&request=GetFeature&typeName=%s&outputFormat=shape-zip&version=1.0.0', sb.id, feature.name)
  file <- GET(query, write_disk(destination, overwrite=T), progress())
  shp.path <- file.path(tempdir(), feature.name)
  dir.create(shp.path)
  unzip(destination, exdir = shp.path)
  return(file.path(shp.path, dir(shp.path)))
}