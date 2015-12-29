library(sp)
library(rgdal)

#supply a lat and long and get an NHD Prmnn_I and state value in return
#example prmnn_i = 10595408	for -93.63417334,	44.49781668

getNHD <- function(x, y) {
  nhd <- readOGR(dsn = getwd(), layer="NHDWaterbody_unique")
  lat <- as.numeric(y)
  lng <- as.numeric(x)
  xy <- cbind(lng,lat)
  pts <- SpatialPoints(xy, proj4string=CRS(proj4string(nhd)))
  inside.nhd <- !is.na(over(pts, as(nhd, "SpatialPolygons"))) 
  pts$nhd <- over(pts, nhd)$Prmnn_I
  return(pts$nhd)
}
