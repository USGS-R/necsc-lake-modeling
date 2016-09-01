depth_summarize = function(config){
	
	data_j = read.table('data/depth_data_linked/depth_herb_jacobson.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	data_l = read.table('data/depth_data_linked/depth_lagos.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	data_ll = read.table('data/depth_data_linked/depth_mn_lakelist.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	data_s = read.table('data/depth_data_linked/depth_swimms_wisconsin.csv', sep=',', header=TRUE, as.is=TRUE)
	
	data_b = read.table('data/depth_data_linked/depth_bathybase.csv', sep=',', header=TRUE, as.is=TRUE)
	
	data_k = read.table('data/depth_data_linked/depth_kevin_michigan.csv', sep=',', header=TRUE, as.is=TRUE)
	
	to_write = rbind(data_j, data_k, data_l, data_s, data_b, data_ll)
	to_write = to_write[, c('id', 'source', 'type', 'zmax')]
	
	#drop all lakes with any NA info (usually in siteID)
	to_write = na.omit(to_write)
	
	zmax = to_write
	saveRDS(zmax, file='data/depth_data_linked/all_depths.rds')
	
	#save with dropped depth for summary file
	write.csv(unique(to_write[, c('id', 'source', 'type')]), 'data/depth_data_linked/depth_data_summary.csv', row.names=FALSE)
}
