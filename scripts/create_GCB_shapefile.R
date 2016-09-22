library(rgdal)
library(dplyr)
m2ft <- 3.28084
gh_layer <- readOGR('hansen_et_al_lakes','hansen_et_al_lakes')
categories <- read.csv('../climate-fish-habitat/cache/fetch/fish_dominance_categories_by_lake_medians.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  rename(WBDY_WBIC=WBIC, early=X1989.2014, mid=X2040.2064, late=X2065.2089)

wally <- read.csv('../climate-fish-habitat/cache/fetch/future_wae_projected_probability.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  group_by(WBIC, Time) %>% summarize(prob.wally = paste0(sprintf('%1.1f', median(probability.good)*100),' %'))
bass <- read.csv('../climate-fish-habitat/cache/fetch/future_lmb_projected_probability.csv', stringsAsFactors = FALSE, header=TRUE) %>% 
  group_by(WBIC, Time) %>% summarize(prob.bass = paste0(sprintf('%1.1f', median(probability.high)*100),' %'))

use.lakes <- categories$WBDY_WBIC

gh_layer <- gh_layer[gh_layer$WBDY_WBIC %in% use.lakes, ]

layer.data <- gh_layer@data
merged.data <- left_join(layer.data, categories)
merged.data$early[is.na(merged.data$early)] = 'not specified'
merged.data$mid[is.na(merged.data$mid)] = 'not specified'
merged.data$late[is.na(merged.data$late)] = 'not specified' 
merged.data <- merged.data %>% 
  select(WBDY_WBIC, WBDY_NAME, ZMAX, SECCHI_AVG, early, mid, late) %>% 
  rename(WBIC = WBDY_WBIC, lake=WBDY_NAME, depth=ZMAX, clarity=SECCHI_AVG) %>% 
  mutate(depth = sprintf('%1.1f ft',depth*m2ft), clarity = sprintf('%1.1f ft',clarity*m2ft))
  

gh_layer@data <- mutate(merged.data, period = '1989-2014') %>% 
  left_join(filter(bass, Time=='1989-2014') %>%  select(-Time)) %>% 
  left_join(filter(wally, Time=='1989-2014') %>%  select(-Time)) %>% 
  select(lake, period, early, prob.bass, prob.wally) %>% rename(time=period, predicted=early)
writeOGR(obj = gh_layer, dsn ='../climate-fish-habitat/data/predicted_species_lakes', layer = 'predicted_species_1989-2014', driver = 'ESRI Shapefile')

gh_layer@data <- mutate(merged.data, period = '2040-2064') %>% 
  left_join(filter(bass, Time=='2040-2064') %>%  select(-Time)) %>% 
  left_join(filter(wally, Time=='2040-2064') %>%  select(-Time)) %>% 
  select(lake, period, mid, prob.bass, prob.wally) %>% rename(time=period, predicted=mid)
writeOGR(obj = gh_layer, dsn ='../climate-fish-habitat/data/predicted_species_lakes', layer = 'predicted_species_2040-2064', driver = 'ESRI Shapefile')

gh_layer@data <- mutate(merged.data, period = '2065-2089') %>% 
  left_join(filter(bass, Time=='2065-2089') %>%  select(-Time)) %>% 
  left_join(filter(wally, Time=='2065-2089') %>%  select(-Time)) %>% 
  select(lake, period, late, prob.bass, prob.wally) %>% rename(time=period, predicted=late)
writeOGR(obj = gh_layer, dsn ='../climate-fish-habitat/data/predicted_species_lakes', layer = 'predicted_species_2065-2089', driver = 'ESRI Shapefile')
