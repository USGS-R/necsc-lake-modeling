library(rgeos)
library(rgdal)
library(raster)

#create_buffered_shapes
necsc_nhd = readOGR('data/NHD_shape_large', layer='NHDWaterbody' )
startProj = proj4string(necsc_nhd)

necsc_nhd = spChFIDs(necsc_nhd, as.character(necsc_nhd@data$Prmnn_I))


#first project to something flat instead of lat/lon
necsc_projected = spTransform(necsc_nhd, CRS( "+init=epsg:26915" ))

necsc_buffered = gBuffer(necsc_projected, width = 100, byid = TRUE)

n = nrow(necsc_projected)
groups = split(1:nrow(necsc_buffered), ceiling(seq_along(necsc_buffered)/1000))
grp_merged= list()

for(j in 1:length(groups)){
  grp_polys = list()
  grp_i = 1
  
  for(i in groups[[j]]){
    
    tmp = necsc_projected[i,]@data
    row.names(tmp) = '1'
    
    grp_polys[[grp_i]] = SpatialPolygonsDataFrame(gDifference(necsc_buffered[i,], necsc_projected[i,]), tmp)
    grp_i = grp_i + 1
    
    cat(100*i/n, '\n')
  }
  grp_merged[[j]] = do.call(bind, grp_polys)
  rm(grp_polys)
  gc()
}

all_buffers = do.call(bind, grp_merged)



writeOGR(all_buffers, dsn='data/NHD_shape_large', layer='NHDWaterbody_100m_buffers', driver='ESRI Shapefile')

shp_files = Sys.glob('data/NHD_shape_large/NHDWaterbody_100m_buffers.*')

library(sbtools)

tmpzip = tempfile(fileext='.zip')

zip(tmpzip, files = shp_files)

item_upload_create(parent_id='5519b6c4e4b0323842783323', files = tmpzip)

