# we ri=un this after restez_fetch_and_build.  It compiles a tally of IDs and orgs in the resetz databases
# After we runn idorg_reducer to winnow the species list of interest.

# For each database in ['plant', 'vertebrate', 'invertebrate', etc] do
#   taxids = restez::list_db_ids() |>
#     restez::gb_organism_get() |>                 
#     save_as_csv() |>
#     compact_idorg |>
#     save_as_another_csv()

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
                         sprintf("%s_%s_idorg.csv.gz", cfg$version, dbname))) |>
        compact_idorg() |>
        readr::write_csv(file.path(cfg$output$path,
                         sprintf("%s_%s_compact.csv.gz", cfg$version, dbname)))
     charlier::info("successfully listed database: %s", dbname)
    })
  
  
    return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cat("args in R:", args, "\n")
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/idorg.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, cfg$version))

# here is a hack. The user always provides a cfgfile (or the default is used)
# if there is a second argument (or more), it will be the value to assign to cfg$restez$dbs
# use this mechanism to batch run idorg (parallel processing for each group)
if (length(args <= 2)){
  cfg$restez$dbs = args[2:(length(args))]
}

if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}