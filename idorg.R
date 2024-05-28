# For each database in ['plant', 'vertebrate', 'invertebrate] do
#   taxids = restez::list_db_ids() |>
#     restez::gb_organism_get() |>
#     some_local_reduction_function_goes_here() |>
#     taxizedb::name2taxid()



main = function(cfg){
  charlier::info("starting version: %s", cfg$version)
  x = lapply(cfg$restez$dbs,
    function(dbname){
      charlier::info("listing database: %s", dbname)
      restez::restez_path_set(file.path(cfg$restez$dbpath, dbname))
      
      taxids = restez::list_db_ids(n = NULL)
      
      if (!is.null(cfg$input$subsample)) {
        charlier::info("subsampling to just %i records out of %i records", cfg$input$subsample, length(taxids))
        set.seed(cfg$input$subsample)
        taxids =sample(taxids, cfg$input$subsample, replace = FALSE)
      } else {
        charlier::info("there are %i taxids available", length(taxids))
      }
      
      charlier::info("getting organisms")
      orgs = restez::gb_organism_get(taxids)
      
      x = dplyr::tibble(id = taxids, org = orgs) |>
      readr::write_csv(file.path(cfg$output$path,
                         sprintf("%s_%s_idorg.csv.gz", cfg$version, dbname)))
    })
  
  
    return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cat("args in R:", args, "\n")
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/idorg.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, cfg$version))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}