#create rough WIBC and NHD crosswalk
library(rgdal)
library(sp)
library(dplyr)
nhd   = readOGR('data/NHD_shape_large', 'NHDWaterbody')
state = readOGR('/Users/jread/Google Drive/Stratification/WisconsinHydroLayer', 'wiscoNoZ_wgs84')
# subset smaller lakes out
min.lake <- 20000 # 2 hectares
max.lake <- 543948812 # just larger than Winnebago
state <- state[state@data$Shape_Area > min.lake & state@data$Shape_Area < max.lake, ]


out = data.frame(WBIC=state$WBDY_WBIC, site_id=NA)

pb = txtProgressBar(min = 0, max = nrow(out), initial=0)

for(i in 1:nrow(out)){
	tmp = over(state[i,], nhd)
	
	if(!is.na(tmp$Prmnn_I[1])){
	  if (length(tmp$Prmnn_I) > 1){
	    id <- (arrange(tmp, desc(AreSqKm)) %>% .$Prmnn_I)[1]
	  } else {
	    id <- tmp$Prmnn_I[1]
	  }
		out$site_id[i] = paste0('nhd_', id)
	}
	setTxtProgressBar(pb, i)
}
nhd2wbic <- filter(out, !is.na(site_id))

write.csv(nhd2wbic, 'data/NHD_state_crosswalk/nhd2WBIC.csv', row.names=FALSE)

save(nhd2wbic, file='data/NHD_state_crosswalk/nhd2wbic.RData')
