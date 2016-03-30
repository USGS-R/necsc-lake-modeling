#temp link LTER data

temp_link_ntl_lter = function(fname){
	
	ntl_phys_limno_url = 'https://portal.lternet.edu/nis/dataviewer?packageid=knb-lter-ntl.29.7&entityid=1932bb71889c8e25cb216c8dc0db33d5'
	ntl = read.table(ntl_phys_limno_url, sep=',', header=TRUE, as.is=TRUE) 
	nhd_ntl = read.table('data/temperature_data/lter.lakes.tsv', sep='\t', header=TRUE, as.is=TRUE)
	
	#id, date, source, type, depth, wtemp
	ntl_linked = merge(ntl, nhd_ntl, by.y="Abbreviation", by.x="lakeid")
	
	ntl_clean = transmute(ntl_linked, id=nhd_id, date=sampledate, source="ntl-lter", type='wtemp', depth=depth, wtemp=wtemp)
	
	write.table(ntl_clean, 'data/temperature_data_linked/temp_ntl_lter.tsv', sep='\t', row.names=FALSE)	
}