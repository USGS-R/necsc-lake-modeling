library(sp)
library(rgdal)

#supply a lat and long and get an NHD Prmnn_I id referring to an NHDWaterbody
#example prmnn_i = 10595408	for -93.63417334,	44.49781668

getNHD <- function(nhd, x, y) {
  nhd<-nhd
  lat <- as.numeric(y)
  lng <- as.numeric(x)
  xy <- cbind(lng,lat)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
  inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
  pts$nhd <- over(pts, nhd, fn = NULL, returnList = FALSE)$Prmnn_I
  prmnn_i <- as.character(pts$nhd)
  return(prmnn_i)
}

