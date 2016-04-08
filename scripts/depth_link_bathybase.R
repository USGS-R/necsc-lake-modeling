fname = "data/depth_data_raw/bathybase_summary.tsv"

depth_link_bathybase = function(fname){
	
	bathybase = read.table(fname, header=TRUE, as.is=TRUE)
	
	bathybase$id = link_to_nhd(bathybase$lat, bathybase$lon)
	
	bathybase$zmax = bathybase$depth_max
	
	bathybase$`source` = 'bathybase'
	bathybase$type     = 'maxdepth'
	
	to_write        = bathybase[,c('id', 'source', 'type', 'zmax')]
	write.table(to_write, 'data/depth_data_linked/depth_bathybase.csv', sep=',', row.names=FALSE)
	
}