# For each database in ['plant', 'vertebrate', 'invertebrate] do
#   taxids = restez::list_db_ids() |>
#     restez::gb_organism_get() |>
#     some_local_reduction_function_goes_here() |>  # <--- this?
#     taxizedb::name2taxid()

main = function(cfg){
  charlier::info("starting version: %s", cfg$version)
  
  if (is.character(cfg) && (cfg[1] == "default")) cfg = default_groupings()
  
  species = readr::read_csv(cfg$input$species_list, col_types = "c") |>
     dplyr::select(dplyr::all_of(cfg$input$name))
  charlier::info("input has %i records",nrow(x)) 
    
  if (cfg$input$sentence_case){
    charlier::info("making sentence case")
    x[[cfg$input$name]] <- stringr::str_to_sentence(x[[cfg$input$name]])
  }
  
  if (cfg$input$deduplicate){
    n = nrow(x)
    ix = duplicated(x[[cfg$input$name]])
    x <- dplyr::filter(x, !ix)
    charlier::info("deduplication removed %i records leaving %i records", nx = n - nrow(x), nrow(x))
  }


  r = dplyr::group_walk(x,
    function(tbl, key){
      y = readr::read_csv(cfg$input$idorg[[key$group]], col_types = "c")|>
        dplyr::group_by(org) |>
        dplyr::group_map(
          function(tbl, key)){
            dplyr::mutate()
          }
      
    }

  
  
 
  return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cat("args in R:", args, "\n")
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/idorg_reduce.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, 
                       sprintf("%s-log", cfg$version)))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}