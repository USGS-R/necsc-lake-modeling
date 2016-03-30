temp_summarize = function(){
	
	data_w = read.table('data/temperature_data_linked/temp_wilma.tsv', sep='\t', header=TRUE, as.is=TRUE)
	data_q = read.table(gzfile('data/temperature_data_linked/temperature_wqp.tsv.gz'), sep='\t', header=TRUE, as.is=TRUE)
	data_q$source = 'wqp'
	
  data_q = dplyr::rename(data_q, date=Date)
	
  data_l = read.table('data/temperature_data_linked/temp_ntl_lter.tsv', sep='\t', header=TRUE, as.is=TRUE)
  data_l = dplyr::select(data_l, id, depth, date, wtemp, source)
	
	temp = rbind(dplyr::select(data_w, id, depth, date, wtemp, source), data_q, data_l)
	temp = na.omit(temp)
	
	write.table(temp, 'data/temperature_data_linked/all_temp.tsv', sep='\t', row.names=FALSE)
	
}


#' 
#' table(temp$source)
#' 
#' wdnr = subset(temp, source=='wdnr')
#' wqp  = subset(temp, source=='wqp')
#' wdnrid = unique(wdnr$id)
#' wqpid  = unique(wqp$id)
#' 
#' length(intersect(wdnr$id, wqp$id))
#' 
#' just_wdnr = subset(wdnr, !(id %in% unique(wqp$id)))
#' 
#' table(just_wdnr$id)
#' 
#' 