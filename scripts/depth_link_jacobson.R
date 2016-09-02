#library(jsonlite)

depth_link_jacobson = function(fname){
	
	#load the pre-made DOWlknum to NHD linking file
	load('data/NHD_state_crosswalk/nhd2dowlknum.RData')
	
	service = "http://maps2.dnr.state.mn.us/cgi-bin/lakefinder_json.cgi?id="
	
	herb_data = read.csv(fname, as.is=TRUE)
	
	
	herb_data = merge(herb_data, nhd2dowlknum, by.x='DOW.Number', by.y='dowlknum')
	herb_data = dplyr::rename(herb_data, id=site_id)
	
	# herb_data$lat = NA
	# herb_data$lon = NA
	# #pad everything with zeros to be 8 digits
	# herb_data$DOW.Number = sprintf('%08i', as.numeric(herb_data$DOW.Number))
	# 
	# for(i in 1:nrow(herb_data)){
	# 	lake_url = paste0(service, herb_data$DOW.Number[i])
	# 	tryCatch({
	# 		res = fromJSON(lake_url)
	# 		
	# 		if(res$status == 'OK'){
	# 			res$results$point[2]
	# 			
	# 			lonlat = res$results$point[['epsg:4326']][[1]]
	# 			herb_data$lat[i] = lonlat[2]
	# 			herb_data$lon[i] = lonlat[1]
	# 		}
	# 	}, error=function(){print('problem on row:', i, ' id:', herb_data$DOW.Number[i])})
	# 	
	# 	if(i%%10 == 0) cat(100*i/nrow(herb_data), '% done\n')
	# 	
	# }
	# 
	# herb_data$id     = link_to_nhd(herb_data$lat, herb_data$lon)
	herb_data$`source` = 'Jacobson'
	herb_data$type     = 'maxdepth'
	herb_data$zmax     = herb_data$LakeMaxDepth..m.
	to_write           = herb_data[,c('id', 'source', 'type', 'zmax')]
		
	write.table(to_write, 'data/depth_data_linked/depth_herb_jacobson.tsv', row.names=FALSE, sep='\t')
}