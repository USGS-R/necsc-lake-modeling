
depth_link_lagos = function(config){
	
	#lagos SB id for depth is 56d87371e4b015c306f6cfb0
	
	sbtools::session_renew(config$sb_user)
	
	tmpdir = tempdir()
	files = item_file_download('56d87371e4b015c306f6cfb0', dest_dir=tmpdir, overwrite_file=TRUE)
	
	lagos = read.table(files[1], header=TRUE, sep='\t', as.is=TRUE)
	
	lagos_sites = unique(lagos[, c('lagoslakeid', 'nhd_lat', 'nhd_long')])
	
	lagos_sites$id = link_to_nhd(lagos_sites$nhd_lat, lagos_sites$nhd_long)
	
	lagos_linked = merge(lagos_sites[,c('id', 'lagoslakeid')], lagos, by='lagoslakeid')
	
	lagos_linked$`source` = 'lagos'
	lagos_linked$type     = 'maxdepth'
	lagos_linked$zmax     = lagos_linked$maxdepth
	
	to_write              = lagos_linked[,c('id', 'source', 'type', 'zmax')]
	write_aes(to_write, 'data/depth_data_linked/depth_lagos.edt', config$LAGOS_KEY)
}
