
#' @param template.file a text file to be used as the template
#' @param text data (list) used to fill in template keys
#' @param file.out file to write the output to
#' @param scripted.text a second list to be appended to \code{text} that is programatically generated
render_FGDC_metadata <- function(template.file, text, file.out, scripted.text = NULL, ...){
  render.text <- append(text, scripted.text)
  if (length(list(...)) > 0){
    render.text <- append(render.text, ...)
  }
  template <- paste(readLines(template.file ),collapse = '\n')
  cat(whisker::whisker.render(template, render.text), file = file.out)
  xml <- xml2::read_xml(file.out)
  xml2::write_xml(xml, file.out)
}
