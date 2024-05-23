#' Assign rows of taxonomy to broad groupings
#'
#' @param x a table of taxonomy as per taxizer output
#' @param cfg configuration list
#' @param default char, the default group name, used also to 
#'  identify the desired groups in the configuration
#' @return the input table with an added 'group' column
group_taxa = function(x, cfg, 
  default = "other"){
  
  
  x = dplyr::mutate(x, group = default)
  
  groups = names(cfg$groupings)
  groups = groups[!(groups %in% default)]
  for (g in groups){
    # iterate over the different specified levels (kingdom, class, etc)
    ix = sapply(names(cfg$groupings[[g]]$filter),
      function(tx){
        vals = cfg$groupings[[g]]$filter[[tx]]
        isneg = grepl("-", substring(vals, 1,1), fixed = TRUE)
        vals[isneg] = substring(vals[isneg], 2)
        # iterate over one or more values to match against at this level
        sapply(seq_along(vals),
          function(i){
            if (isneg[i]){
              r = !(x[[tx]] == vals[i])
            } else {
              r = x[[tx]] == vals[i]
            }
            r
          })|>
          apply(1, any_true)  # <- this means we are ORing
      }) |>
      apply(1, all_true)
    x$group[ix] <- g
    
  }
  x
}




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