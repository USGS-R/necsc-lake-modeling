#check variable names

loadConfig()

opt <- options()$necsc

driver.name = 'ECHAM5'
base.url <- sprintf('http://cida-test.er.usgs.gov/mda.lakes/drivers_GLM_%s', driver.name)
var<- 'precip'
drivers <- read.table(file.path(base.url, 'driver_index.tsv'), header = T, sep = '\t', stringsAsFactors = FALSE)
library(dplyr)
library(httr)

.dots <- list(~variable == var)

files <- filter_(drivers, .dots=.dots) %>%
  select(file.name) %>% 
  mutate(verified=FALSE)
  


for (i in 1:nrow(files)){
  file = files$file.name[i]

  if (!files$verified[i]){
    temp.file <- file.path(tempdir(), file)
    flag = tryCatch({
      GET(file.path(base.url, file), write_disk(temp.file, overwrite=TRUE))
      FALSE
    }, error = function(e) {
      message(e)
      return(TRUE)
    })
    if (!flag){
      load(temp.file)
      if (any(names(data.site) != c('DateTime',var))){
        names(data.site) <- c('DateTime',var)
        save(data.site, file = temp.file, compress="xz")
        output <- system(sprintf('rsync -rP %s %s@cidasdpdfsuser.cr.usgs.gov:%s%s', temp.file, opt$necsc_user, paste0(opt$driver_dir, sprintf('drivers_GLM_%s/', driver.name)), file),
                         ignore.stdout = TRUE, ignore.stderr = TRUE)
        if (!output)
          files$verified[i] <- TRUE
        cat('*')
      } else {
        cat('|')
        files$verified[i] <- TRUE
      }# else do nothing with this file
      unlink(temp.file)
    }
  } else {
    cat('-')
  }
}
