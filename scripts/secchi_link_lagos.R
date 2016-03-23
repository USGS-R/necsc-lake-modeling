
#LAGOS secchi SB item 56d8735ee4b015c306f6cfab
#library(rgdal)

secchi_link_lagos = function(config){

	if(!sbtools::is_logged_in()){
		authenticate_sb(config$sb_user)
	}
	
	tmpdir = tempdir()
	files = item_file_download('56d8735ee4b015c306f6cfab', dest_dir=tmpdir, overwrite_file=TRUE)
	
	lagos = read.table(files[1], header=TRUE, sep='\t', as.is=TRUE)
	
	lagos_sites = unique(lagos[, c('lagoslakeid', 'nhd_lat', 'nhd_long')])
	
	lagos_sites$id = link_to_nhd(lagos_sites$nhd_lat, lagos_sites$nhd_long)
	
	lagos_linked = merge(lagos_sites[,c('id', 'lagoslakeid')], lagos, by='lagoslakeid')
	
	lagos_linked$`source` = 'lagos'
	lagos_linked$type     = 'secchi'
	lagos_linked$date = lagos_linked$sampledate
	
	to_write              = lagos_linked[,c('id','date', 'source', 'type', 'secchi')]
	write_aes(to_write, 'data/secchi_data_linked/secchi_lagos.edt', config$LAGOS_KEY)
	
}