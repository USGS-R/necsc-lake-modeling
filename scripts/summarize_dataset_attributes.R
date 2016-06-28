summarize_dataset_attributes <- function(filename){
  dataset <- read.table(filename, header = TRUE, sep = '\t', stringsAsFactors = FALSE) 
}

submissing <- function(value, sub.val = 'NA'){
  ifelse(!is.na(value) & value != '',value,sub.val)
}

read_habitat_metrics <- function(filename){
  metrics <- read.table(filename, header = TRUE, sep = ',', stringsAsFactors = FALSE) 
  out <- list()
  for (metric in metrics$attribute){
    i <- which(metric == metrics$attribute)[1]
    out[[i]] <- list('attr-label' = metric,
                     'attr-def' = submissing(metrics$Specific.metric[i]),
                     'attr-defs'=submissing(metrics$Reference[i]),
                     'data-min'='NA', # from data
                     'data-max'='NA', # from data
                     'data-units'=submissing(metrics$units[i]))
  }
  return(list(attributes=out))
}