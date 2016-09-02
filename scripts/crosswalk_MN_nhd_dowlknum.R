#create rough DOWlk and NHD crosswalk
library(rgdal)
library(sp)

state = readOGR('data/NHD_state_crosswalk/MN', 'dnr_hydro_features_all')
nhd   = readOGR('data/NHD_shape_large', 'NHDWaterbody')

state = state[!is.na(state$dowlknum), ]
state = state[state$dowlknum != '00000000', ]

#project
state = spTransform(state, nhd@proj4string)

out = data.frame(dowlknum=state$dowlknum, site_id=NA)

pb = txtProgressBar(min = 0, max = nrow(out), initial=0)

for(i in 1:nrow(out)){
	tmp = over(state[i,], nhd)
	
	if(!is.na(tmp$Prmnn_I)){
		out$site_id[i] = paste0('nhd_', tmp$Prmnn_I[1])
	}
	setTxtProgressBar(pb, i)
}

write.csv(out, 'data/NHD_state_crosswalk/MN_nhd2dowlknum.csv', row.names=FALSE)
nhd2dowlknum = out
save(nhd2dowlknum, file='data/NHD_state_crosswalk/nhd2dowlknum.RData')
