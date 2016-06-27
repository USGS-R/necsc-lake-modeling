

get_nlcd_classes <- function(lake.buffer, filename){
  nlcd.file = 'data/NLCD_data/nlcd_2011_landcover_2011_edition_2014_10_10/nlcd_2011_landcover_2011_edition_2014_10_10.img'
  NLCD = raster(nlcd.file)
  
  nlcd.classes <- data.frame(class = c(0, 11,12,21,22,23,24,31,41,42,43,51,52,71,72,73,74,81,82,90,95),
                             type=c('No Data', 'Open Water','Perennial Ice/Snow','Developed, Open Space','Developed, Low Intensity',
                                    'Developed, Medium Intensity','Developed, High Intensity','Barren Land (Rock/Sand/Clay)',
                                    'Deciduous Forest','Evergreen Forest','Mixed Forest','Dwarf Scrub','Scrub/Shrub','Grassland/Herbaceous',
                                    'Sedge/Herbaceuous','Lichens','Moss','Pasture/Hay','Cultivated Crops','Woody Wetlands','Emergent Herbaceous Wetlands'))
  
  lakes <- shapefile(lake.buffer)

  shelter.lakes <- spTransform(lakes,CRSobj = CRS(proj4string(NLCD)))   
  ids <- paste0('nhd_', shelter.lakes$Prmnn_I)
  # loop through lakes, crop and mask, remove NAs (from mask), calc class percentages, bind:
  
  data.out <- matrix(data = NA, nrow = length(ids), ncol = nrow(nlcd.classes))
  for (i in 1:length(ids)){
    lake <- shelter.lakes[i, ]
    
    buffer.data <- crop(NLCD, lake) %>% 
      mask(lake) %>% 
      freq() %>% data.frame %>% filter(!is.na(value))
    tot.px <- sum(buffer.data$count)
    data.out[i, ] <- mutate(buffer.data, perc = count/tot.px*100) %>% 
      rename(class=value) %>% 
      right_join(nlcd.classes, by="class") %>% arrange(class) %>% mutate(perc=ifelse(is.na(perc), 0, perc)) %>% 
      select(class, perc) %>% 
      tidyr::spread(key='class','perc') %>% as.numeric
    
    if (i %% 100 == 0)
      cat(i,' of ', length(ids))
    cat('.')
  }
  shelter.out <- data.frame(data.out) %>% setNames(paste0('nlcd.class.',nlcd.classes$class)) %>% 
    cbind(data.frame(id=ids))
  write.table(shelter.out, file='land_cover_MGLP.tsv', sep='\t', row.names=FALSE, quote=FALSE)
}


get_dominant_nlcd <- function(lake.buffer, filename){
  nlcd.file = 'data/NLCD_data/nlcd_2011_landcover_2011_edition_2014_10_10/nlcd_2011_landcover_2011_edition_2014_10_10.img'
  NLCD = raster(nlcd.file)
  
  
  lakes <- shapefile(lake.buffer)
  
  # remove all lakes that are not in the analysis
  lake.ids <- lake_summary_locations()$id
  Prmnn_Ids <- unlist(lapply(strsplit(lake.ids,'[_]'), function(x) x[2]))
  shelter.lakes <- lakes[lakes$Prmnn_I %in% Prmnn_Ids, ]
  if (length(lake.ids) != length(shelter.lakes$Prmnn_I))
    stop('unequal matching found for lake shapefile and project depth summary file')
  
  # reproject shapefile to same CRS as NLCD
  shelter.lakes <- spTransform(shelter.lakes,CRSobj = CRS(proj4string(NLCD)))   
  
  # loop through lakes, crop and mask, remove NAs (from mask), take dominant non-water count:
  shelter.out <- data.frame(id=lake.ids, dom.class=NA, stringsAsFactors = FALSE)
  for (i in 1:length(lake.ids)){
    id <- shelter.out$id[i]
    Prmnn_I <- strsplit(id, '[_]')[[1]][2]
    lake <- shelter.lakes[shelter.lakes$Prmnn_I == Prmnn_I, ]
    shelter.out$dom.class[i] <- crop(NLCD, lake) %>% 
      mask(lake) %>% 
      freq() %>% 
      data.frame() %>% 
      filter(!is.na(value), value != 11) %>% 
      filter(count == max(count)) %>% {.$value[1]}# remove mask vals and open water
    cat('.')
  }
  
  write.table(shelter.out, file=filename, sep='\t', row.names=FALSE, quote=FALSE)
}

hc_from_NLCD <- function(mapping.file, nlcd.file, file.out){
  nlcd <- read.table(nlcd.file, sep='\t', header=TRUE, stringsAsFactors=FALSE)
  mapping <- read.table(mapping.file, sep='\t', header=TRUE, stringsAsFactors=FALSE)
  
  names(nlcd) <- c('id','nlcd.class')
  data.out <- left_join(nlcd, mapping) %>% 
    select(id, hc.value) %>% 
    rename(hc.meters=hc.value)
  write.table(data.out, file=file.out, sep='\t', row.names=FALSE, quote=FALSE)
  
}
