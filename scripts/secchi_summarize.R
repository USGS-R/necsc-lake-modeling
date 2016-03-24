secchi_summarize = function(config){
	
	data_w = read.table('data/secchi_data_linked/secchi_wilma.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	data_l = read_aes('data/secchi_data_linked/secchi_lagos.edt', config$LAGOS_KEY)
	
	data_q = read.table(gzfile('data/secchi_data_linked/secchi_wqp.tsv.gz'), sep='\t', header=TRUE, as.is=TRUE)
	data_q = transmute(data_q, source='wqp', type='secchi', date=Date, id=id, secchi=secchi)
	
	to_write = rbind(data_w, data_l, data_q)
	
	to_write = to_write[, c('id', 'date', 'source', 'type', 'secchi')]
	
	#drop all lakes with any NA info (usually in siteID)
	to_write = na.omit(to_write)
	
	write_aes(to_write, 'data/secchi_data_linked/all_secchi.edt', key = config$LAGOS_KEY)
	
	#save with dropped depth for summary file
	write.csv(to_write[, c('id', 'source', 'type')], 'data/secchi_data_linked/secchi_data_summary.csv', row.names=FALSE)
	
}