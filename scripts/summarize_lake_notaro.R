# Would it be possible to same the daily mean (seasonal cycle) and daily interannual variability (standard deviation) for all variables and all depths
# for all output variables?
# 
# So, an arbitrary example for a given depth:
#   Date     1980    1981    1982    1983 etc....    Mean across years    Standard Dev across years
# Jan 1      12C      13C       10C     14C                           12.3C                             1.7C
# Jan 2      11C      12C        8C       12C                           10.8C                            1.9C
# etc....
# 
# So, we can throw out the raw data and just save the across-year means and across-year standard deviations for each day and each depth, per variable.
# That should be much less data.
# 
# How does this sound?  If that is ok, can you run 1 lake and let me see this output before running more?
# 
# Thanks so much, Michael

library(mda.lakes)
library(lakeattributes)
library(glmtools)
library(dplyr)
library(tidyr)
library(lubridate)
id <- 'nhd_13344210'
driver.path = get_driver_path(id, driver_name="NLDAS")
nml = populate_base_lake_nml(id, kd=0.3, driver = driver.path)
nml = set_nml(nml, arg_list=list('start'='1979-01-04 00:00:00', 'stop'='2015-12-31 00:00:00'))
write_nml(nml, file=file.path(tempdir(),'glm2.nml'))
run_glm(tempdir())

exclude.vars <- c("extc_coef", "salt")
nc.file <- file.path(tempdir(), 'output.nc')
var.names <- as.character(sim_vars(nc.file)$name)

# for the 1D vars, get depths and summarize, for annual scale

summarize_var_notaro <- function(nc.file, var.name){
  unit <- sim_var_units(nc.file, var.name)
  is.1D <- glmtools:::.is_heatmap(nc.file, var.name)
  value.name <- sprintf('%s%s', var.name, ifelse(unit=='', '',paste0(' (',unit,')')))
  if (is.1D){
    rename_depths <- function(depths){
      unlist(lapply(strsplit(depths, '[_]'), function(x) sprintf('%s_%s', round(eval(parse(text=head(tail(x,2),1))), digits = 2), tail(x,1))))
    }
    get_depth <- function(names){
      as.numeric(unname(unlist(sapply(names, function(x) strsplit(x,'[_]')[[1]][1]))))
    }
    get_stat <- function(names){
      unname(unlist(sapply(names, function(x) strsplit(x,'[_]')[[1]][2])))
    }
    var <- get_var(nc.file, var.name, reference='surface') %>% 
      mutate(year=lubridate::year(DateTime)) %>% group_by(year) %>% 
      summarize_each_(c('mean','sd'), list(quote(-DateTime))) %>% 
      setNames(c('year',rename_depths(names(.)[-1L]))) %>% gather(key = year) %>% 
      setNames(c('year','depth_stat','value')) %>% 
      mutate(depth=get_depth(depth_stat), statistic=get_stat(depth_stat), variable=value.name) %>% 
      select(year, depth, statistic, value, variable)
    #year depth statistic     value       variable
  } else {
    var <- get_var(nc.file, var.name)%>% 
      mutate(year=lubridate::year(DateTime)) %>% group_by(year) %>% 
      summarize_each_(c('mean','sd'), list(quote(-DateTime))) %>% gather(key = year) %>% 
      setNames(c('year','statistic','value')) %>% 
      mutate(depth=NA, variable=value.name) %>% 
      select(year, depth, statistic, value, variable)
  }
  
  return(var)
}

lake.data = lapply(var.names[!var.names %in% exclude.vars], function(x) summarize_var_notaro(nc.file, x))
df.data <- data.frame()
for (i in 1:length(lake.data)){
  df.data <- rbind(df.data, lake.data[[i]])
}

write.table(df.data, file='lake_summary_stats.tsv', quote = FALSE, sep = '\t', row.names = FALSE)
