library(rgdal)
library(dplyr)
m2ft <- 3.28084
gh_layer <- readOGR('/Users/jread/Downloads/hansen_et_al_lakes','hansen_et_al_lakes')
categories <- read.csv('../climate-fish-habitat/cache/fetch/fish_dominance_categories_by_lake_medians.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  rename(WBDY_WBIC=WBIC, early=X1989.2014, mid=X2040.2064, late=X2065.2089)

wally <- read.csv('../climate-fish-habitat/cache/fetch/future_wae_projected_probability.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  group_by(WBIC, Time) %>% summarize(prob.wally = median(probability.good)) %>% rename(WBDY_WBIC=WBIC)
bass <- read.csv('../climate-fish-habitat/cache/fetch/future_lmb_projected_probability.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  group_by(WBIC, Time) %>% summarize(prob.bass = median(probability.high)) %>% rename(WBDY_WBIC=WBIC)

use.lakes <- categories$WBDY_WBIC

gh_layer_subset <- gh_layer[gh_layer$WBDY_WBIC %in% use.lakes, ]

merged.data <- gh_layer_subset@data %>% 
  select(-SHAID_NO, -CANOPY_HEI) %>% 
  mutate(AREA=mda.lakes::getArea(WBDY_WBIC), SP_ID = 0:(nrow(gh_layer_subset@data)-1)) %>% 
  left_join(filter(bass, Time=='1989-2014')) %>% rename(BASS_PRB1=prob.bass) %>% select(-Time) %>% 
  left_join(filter(bass, Time=='2040-2064')) %>% rename(BASS_PRB2=prob.bass) %>% select(-Time) %>% 
  left_join(filter(bass, Time=='2065-2089')) %>% rename(BASS_PRB3=prob.bass) %>% select(-Time) %>% 
  left_join(filter(wally, Time=='1989-2014')) %>% rename(WALL_PRB1=prob.wally) %>% select(-Time) %>% 
  left_join(filter(wally, Time=='2040-2064')) %>% rename(WALL_PRB2=prob.wally) %>% select(-Time) %>% 
  left_join(filter(wally, Time=='2065-2089')) %>% rename(WALL_PRB3=prob.wally) %>% select(-Time)
  

gh_layer_subset@data <- merged.data
writeOGR(obj = gh_layer_subset, dsn ='gh_release/spatial', layer = 'lake_metadata', driver = 'ESRI Shapefile')

d = group_by(merged.data, WBDY_WBIC) %>% 
  summarize(area=min(AREA), wally.1=min(WALL_PRB1), wally.2=min(WALL_PRB2), wally.3=min(WALL_PRB3),
            bass.1=min(BASS_PRB1), bass.2=min(BASS_PRB2), bass.3=min(BASS_PRB3))
#total area
sum(d$area)/1000000
sum(d$area[d$wally.1>0.49])/1000000
sum(d$area[d$wally.2>0.49])/1000000
sum(d$area[d$wally.3>0.49])/1000000

sum(d$area[d$bass.1>0.49])/1000000
sum(d$area[d$bass.2>0.49])/1000000
sum(d$area[d$bass.3>0.49])/1000000
