library(rgeos)
library(rgdal)

#create_buffered_shapes
necsc_nhd = readOGR('data/NHD_shape_large', layer='NHDWaterbody' )
startProj = proj4string(necsc_nhd)


#first project to something flat instead of lat/lon
necsc_projected = spTransform(necsc_nhd, CRS( "+init=epsg:26915" )) 

necsc_buffered = gBuffer(necsc_projected, width = 100, byid=TRUE)

necsc_buffered = SpatialPolygonsDataFrame(necsc_buffered, necsc_buffered@data)

#plot(buffered, col='red')
#lines(tobuffer_trans, col='green')

groups = split(necsc_buffered, ceiling(seq_along(necsc_buffered)/1000))
#splits = rep(1:10, length(necsc_buffered)/10)
# 
# groups = lapply(1:10, function(grp){
# 	
# 	
# 	subset(necsc_buffered, splits == grp)
# 	
# })

necsc_buffer_only = gDifference(necsc_projected[necsc_projected@data$Prmnn_I %in% groups[[1]]@data$Prmnn_I, ], groups[[1]], byid=TRUE)

for(i in 2:length(groups)){
	
	tmp = gDifference(necsc_projected[necsc_projected@data$Prmnn_I %in% groups[[i]]@data$Prmnn_I, ], groups[[i]], byid=TRUE)
	necsc_buffer_only = rbind(necsc_buffer_only, tmp)
	cat(i, '\n')
}

necsc_projected = spTransform(necsc_nhd, startProj) 

plot(necsc_buffer_only, col='green')

#write new shape file


