depth_summarize = function(config){
	
	data_j = read.table('data/depth_data_linked/depth_herb_jacobson.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	data_l = read_aes('data/depth_data_linked/depth_lagos.edt', config$LAGOS_KEY)
	
	data_s = read.table('data/depth_data_linked/depth_swimms_wisconsin.csv', sep=',', header=TRUE, as.is=TRUE)
	
	data_b = read.table('data/depth_data_linked/depth_bathybase.csv', sep=',', header=TRUE, as.is=TRUE)
	
	to_write = rbind(data_j, data_l, data_s, data_b)
	to_write = to_write[, c('id', 'source', 'type', 'zmax')]
	
	#drop all lakes with any NA info (usually in siteID)
	to_write = na.omit(to_write)
	
	write_aes(to_write, 'data/depth_data_linked/all_depths.edt', key = config$LAGOS_KEY)
	
	#save with dropped depth for summary file
	write.csv(to_write[, c('id', 'source', 'type')], 'data/depth_data_linked/depth_data_summary.csv', row.names=FALSE)
}
