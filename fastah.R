

main = function(cfg){
  
  x = readr::read_csv(cfg$input$filename, col_types = "c")
  if (!is.null(cfg$input$subsample)){
    set.seed(cfg$input$subsample)
    x = dplyr::slice_sample(x, n = cfg$input$subsample, replace = FALSE)
  }
  
  x = group_taxa(x, cfg)
  
  
  
  
  
  
}

source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/fastah.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, sprintf("fastah-%s", cfg$version)))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}