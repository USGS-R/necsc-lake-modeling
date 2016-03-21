link_to_nhd = function(lat, lon){
	#get nhd layer
	nhd       = readOGR(dsn = file.path(getwd(),"data", "NHD_shape_large"), layer="NHDWaterbody")
	id_prefix = 'nhd_'
	
	ids = rep(NA, length(lat))
	
	not_na = which(!is.na(lat) & !is.na(lon))
	
	xy = cbind(lon, lat)
	
	pts = SpatialPoints(xy[not_na,], proj4string=CRS(proj4string(nhd)))
	prmids = as.character(over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I)
	
	prefix_prmids = paste0(id_prefix, prmids)
	prefix_prmids[is.na(prmids)] = NA
	
	ids[not_na] = prefix_prmids
	
	
	
# 	
# 	#get the matches between the lat lng pairs and nhd layer
# 	for (i in 1:length(lat)) {
# 		x <- as.numeric(lon[i])
# 		y <- as.numeric(lat[i])
# 		xy <- cbind(x,y)
# 		
# 		if(any(is.na(xy))){
# 			next
# 		}
# 		pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
# 		inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
# 		pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
# 		prmnn_i <- as.character(pts$nhd)
# 		ids[i] <- prmnn_i
# 	}
	
	return(ids)
}
