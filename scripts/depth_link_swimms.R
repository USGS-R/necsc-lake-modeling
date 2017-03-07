
depth_link_swimms = function(fname, crosswalk){
	
  nhd2wbic <- read.csv('data/NHD_state_crosswalk/nhd2WBIC.csv', stringsAsFactors = FALSE)
	sw.pip = read.table(fname, header=TRUE, sep='\t', as.is=TRUE, comment.char = "") %>% 
	  mutate(zmax = Official.Max.Depth * 0.3048) %>% 
	  rename(WBIC=Waterbody.ID.Code..WBIC.) %>% 
	  filter(Official.Max.Depth...Units == 'FEET', !is.na(zmax)) %>% 
	    
	  select(WBIC, Latitude, Longitude, Lake.Name, zmax)

	
	write.table(swimms, 'data/depth_data_linked/depth_swimms_wisconsin.csv', sep=',', row.names=FALSE)
	
}
