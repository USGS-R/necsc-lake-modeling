

depth_link_mnlakelist = function(fname){
	
	#load the pre-made DOWlknum to NHD linking file
	load('data/NHD_state_crosswalk/nhd2dowlknum.RData')
	
	lakelist = read.table(fname, sep='\t', header=TRUE, as.is=TRUE, comment.char = '', 
												quote=NULL, colClasses=c('DOW_NBR_PRIMARY'='character', 'DOW_SUB_BASIN_NBR_PRIMARY'='character'))
	
	lakelist$DOWNUM = paste0(lakelist$DOW_NBR_PRIMARY, lakelist$DOW_SUB_BASIN_NBR_PRIMARY)
	
	lakelist$zmax   = lakelist$MAX_DEPTH_FEET * 0.3048
	
	lakelist = merge(lakelist, nhd2dowlknum, by.y='dowlknum', by.x='DOWNUM')
	lakelist = dplyr::rename(lakelist, id=site_id)
	
	#lakelist$id     = link_to_nhd(lakelist$LAKE_CENTER_LAT_DD5, lakelist$LAKE_CENTER_LONG_DD5)
	lakelist$source = 'mn_lakelist'
	lakelist$type   = 'maxdepth'
	
	to_write        = lakelist[,c('id', 'source', 'type', 'zmax')]
	
	write.table(to_write, 'data/depth_data_linked/depth_mn_lakelist.tsv', row.names=FALSE, sep='\t')
	
}