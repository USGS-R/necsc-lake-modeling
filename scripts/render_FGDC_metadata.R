
#' @param template.file a text file to be used as the template
#' @param text data (list) used to fill in template keys
#' @param file.out file to write the output to
render_FGDC_metadata <- function(template.file, text, file.out){
  template <- paste(readLines(template.file ),collapse = '\n')
  cat(whisker::whisker.render(template, text), file = file.out)
  xml <- xml2::read_xml(file.out)
  xml2::write_xml(xml, file.out)
}
