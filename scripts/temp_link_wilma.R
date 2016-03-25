temp_link_wilma = function(swimms, isermann){
	#swimms='data/temperature_data/swimms.wtemp.obs.tsv'
	#isermann='data/temperature_data/surface_temp_data_2012_2013_Isermann.csv'
	
	
	data_s = read.table(swimms, header=TRUE, sep='\t', as.is=TRUE)
	data_i = read.table(isermann, header=TRUE, sep=',', as.is=TRUE)
	
	data_i = transmute(data_i, site_id=paste0('WBIC_', WBIC), date=Date, depth=0, wtemp=AvgDailySurfTempC)
	data_s = transmute(data_s, site_id=paste0('WBIC_', WBIC), date=DATETIME, depth=DEPTH, wtemp=WTEMP)
	
	wtemp = rbind(data_i, data_s)
	wtemp$type  = 'wtemp'
	wtemp$source= 'wdnr'
	
	##link to lat/lon table and then link to NHD
	wbic_loc = read.table('data/secchi_data_raw/WI_Lakes_WbicLatLon.tsv', sep='\t', header=TRUE)
	wbic_loc$site_id = paste0('WBIC_', wbic_loc$WBIC)
	
	wbic_loc = subset(wbic_loc, site_id %in% wtemp$site_id)
	
	wbic_loc$id = link_to_nhd(wbic_loc$LAT, wbic_loc$LON)
	
	wtemp_linked = merge(wtemp, wbic_loc, by='site_id')
	
	write.table(wtemp_linked[,c('id','date', 'source', 'type', 'depth', 'wtemp')], 
							'data/temperature_data_linked/temp_wilma.tsv', 	sep='\t', row.names=FALSE)
	
}