temp_summarize = function(){
	
	data_w = read.table('data/temperature_data_linked/temp_wilma.tsv', sep='\t', header=TRUE, as.is=TRUE)
	data_q = read.table(gzfile('data/temperature_data_linked/temperature_wqp.tsv.gz'), sep='\t', header=TRUE, as.is=TRUE)
	
	data_q = dplyr::rename(data_q, date=Date)
	
	temp = rbind(dplyr::select(data_w, id, depth, date, wtemp), data_q)
	
	write.table(temp, 'data/temperature_data_linked/all_temp.tsv', sep='\t', row.names=FALSE)
	
}