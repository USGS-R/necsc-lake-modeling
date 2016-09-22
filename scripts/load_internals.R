
load_internals = function(filename) {
  if (missing(filename)) {
    filename <- file.path(Sys.getenv("HOME"), ".R", "necsc.yaml")
  }
  
  config <- yaml::yaml.load_file(filename)
  options("necsc"=config)
}