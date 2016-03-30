
secchi_link_wilma = function(){
	## data from swims
	swims = read.table(gzfile('data/secchi_data_raw/secchi_data_swims_in_situ_fixed.csv.gz'), sep=',', 
										 header=TRUE, as.is=TRUE, quote="\"", comment.char="")
	
	swims_clean = transmute(swims, site_id=paste0('WBIC_', WBIC), year=year(as.Date(START_DATETIME)),
													date=START_DATETIME, secchi=secchi.m, source='swimms', type='in-situ')
	
	## Personal communication from Max Wolter (WDNR), dug up from archives
	sawyer = read.table('data/secchi_data_raw/historical_sawyer_secchi.tsv', sep='\t', header=TRUE)
	
	sawyer_clean = transmute(sawyer, site_id=lake_id, year=year(as.POSIXct(datetime)),
													 date=datetime, secchi=secchi_meter, source='wdnr', type='in-situ')
	
	## satellite secchi data (from Steve Greb)
	satellite = read.table('data/secchi_data_raw/annual_mean_secchi.txt', sep='\t', header=TRUE)
	
	warning('Giving all satellite secchi annual means a date of June 15th as we don\'t know the date, only year ',
					'Do not use satellite data for timeseries analysis')
	
	satellite_clean = transmute(satellite, site_id=paste0('wbic_', WBIC), year=year,
															date=paste0(year,'-06-15'), secchi=secchi.m.mean, type='satellite', source='wdnr')
	
	
	## NTL LTER secchi data
	lter = read.table('data/secchi_data_raw/lter_data.tsv', sep='\t', header=TRUE)
	lter$type = 'in-situ'
	lter$source = 'ntl-lter'
	lter$secchi = lter$secchi_m
	lter$secchi_m = NULL
	
	secchi = rbind(swims_clean, sawyer_clean, satellite_clean, lter)
	
	################################################################################
	## now link secchi data linked to WBIC to lat/lon
	wbic_loc = read.table('data/secchi_data_raw/WI_Lakes_WbicLatLon.tsv', sep='\t', header=TRUE)
	wbic_loc$site_id = paste0('WBIC_', wbic_loc$WBIC)
	
	wbic_loc = subset(wbic_loc, site_id %in% secchi$site_id)
	
	################################################################################
	## ... and link to NHD
	wbic_loc$id = link_to_nhd(wbic_loc$LAT, wbic_loc$LON)
	
	secchi_linked = merge(secchi, wbic_loc, by='site_id')
	
	
	write.table(secchi_linked[,c('id','date', 'source', 'type', 'secchi')], 'data/secchi_data_linked/secchi_wilma.tsv', 
							sep='\t', row.names=FALSE)
	
}
