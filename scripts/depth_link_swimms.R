
depth_link_swimms = function(fname, crosswalk){
	
  load(crosswalk)

	swimms = read.table(fname, header=TRUE, sep='\t', as.is=TRUE, comment.char = "") %>% 
	  dplyr::mutate(zmax = Official.Max.Depth * 0.3048, type='maxdepth', source='swimms') %>% 
	  dplyr::rename(WBIC = Waterbody.ID.Code..WBIC.) %>% 
	  dplyr::left_join(nhd2wbic, by="WBIC") %>% 
	  dplyr::rename(id = site_id) %>% 
	  dplyr::filter(Official.Max.Depth...Units == 'FEET', !is.na(zmax), !is.na(id)) %>% 
	  dplyr::select(id, source, type, zmax)
	
	write.table(swimms, 'data/depth_data_linked/depth_swimms_wisconsin.csv', sep=',', row.names=FALSE)
	
}
