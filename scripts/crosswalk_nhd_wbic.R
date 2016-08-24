#create rough WIBC and NHD crosswalk
library(rgdal)
library(sp)

state = readOGR('data/NHD_state_crosswalk', 'managed_wiscoNoZ_wgs84')
nhd   = readOGR('data/NHD_shape_large', 'NHDWaterbody')

out = data.frame(WBIC=state$WBDY_WBIC, site_id=NA)

pb = txtProgressBar(min = 0, max = nrow(out), initial=0)

for(i in 1:nrow(out)){
	tmp = over(state[i,], nhd)
	
	if(!is.na(tmp$Prmnn_I)){
		out$site_id[i] = paste0('nhd_', tmp$Prmnn_I[1])
	}
	setTxtProgressBar(pb, i)
}

write.csv(out, 'data/NHD_state_crosswalk/nhd2WBIC.csv', row.names=FALSE)
nhd2wbic = out
save(nhd2wbic, file='data/NHD_state_crosswalk/nhd2wbic.RData')
