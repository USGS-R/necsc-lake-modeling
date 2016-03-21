
depth_link_kevin = function(fname){
	
	kevin = read.csv(fname, header=TRUE, as.is=TRUE)
	
	kevin$id = link_to_nhd(kevin$Lat_Cent, kevin$Long_Cent)
	
	kevin$zmax = kevin$MaxDepth_f * 0.3048
	
	kevin$`source` = 'kevin'
	kevin$type     = 'maxdepth'
	
	to_write        = kevin[,c('id', 'source', 'type', 'zmax')]
	write.table(to_write, 'data/depth_data_linked/depth_kevin_michigan.csv', sep=',', row.names=FALSE)
	
}
