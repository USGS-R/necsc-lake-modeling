
depth_link_swimms = function(fname){
	
	swimms = read.table(fname, header=TRUE, sep='\t', as.is=TRUE, comment.char = "")
	
	swimms$id = link_to_nhd(swimms$Latitude, swimms$Longitude)
	
	swimms$zmax = swimms$Official.Max.Depth
	swimms$zmax[swimms$Official.Max.Depth...Units == 'FEET'] = swimms$zmax[swimms$Official.Max.Depth...Units == 'FEET'] * 0.3048
	
	swimms$`source` = 'swimms'
	swimms$type     = 'maxdepth'
	
	to_write        = swimms[,c('id', 'source', 'type', 'zmax')]
	write.table(to_write, 'data/depth_data_linked/depth_swimms_wisconsin.csv', sep=',', row.names=FALSE)
	
}
