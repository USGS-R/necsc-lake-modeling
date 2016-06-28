summarize_dataset_attributes <- function(filename){
  dataset <- read.table(filename, header = TRUE, sep = '\t', stringsAsFactors = FALSE) 
}

read_habitat_metrics <- function(filename){
  metrics <- read.table(filename, header = TRUE, sep = ',', stringsAsFactors = FALSE) 
}