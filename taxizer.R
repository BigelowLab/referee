#' Pretty simple... given a vector of species (binomial) do all one can to 
#' generate a table of species, ncbi-id, superkingdom, kingdom, phylum, class, order, family, genus, species
#'
#' Calling sequence:
#' $Rscript /path/to/taxizer.R /path/to/config.yaml


main = function(cfg){
  charlier::info("starting version %s", cfg$version)
  x = readr::read_csv(cfg$input$filename, show_col_types = FALSE) |>
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
  
  
  if (!is.null(cfg$input$subsample)) {
    charlier::info("subsampling to just %i records", cfg$input$subsample)
    set.seed(cfg$input$subsample)
    x = dplyr::slice_sample(x, n = cfg$input$subsample)
  }

  charlier::info("searching taxonomy")
  
  # here we break into the specified chunk size
  steps = ceiling(nrow(x)/cfg$tax_db$chunk)
  index = rep(seq_len(steps), each = cfg$tax_db$chunk, length = nrow(x))
  charlier::info("configuring %i steps of %i chunks", steps, cfg$tax_db$chunk)
  lost = dplyr::tibble()
  y <- x[cfg$input$name] |>
    dplyr::mutate(index_ = index) |>
    dplyr::group_by(index_) |>
    dplyr::group_map(
      function(tbl, key){
        charlier::info("chunk %i", key$index_[1])
        Sys.sleep(cfg$tax_db$sleep)
        r = try(taxizedb::classification(tbl[[1]], db=cfg$tax_db$db))
        if (!inherits(r, "try-error")){
          if (length(r) != nrow(tbl)){
            # all NA maybe?
            lost = dplyr::bind_rows(lost, tbl)
            r = NULL
          } else {
            r = r |>
              reform_classification() |>
              tabulate_classification()
          }
        } else {
          lost = dplyr::bind_rows(lost, tbl)
          r = NULL
        } 
        
        r
      }) |>
      dplyr::bind_rows()|>  
      readr::write_csv(file.path(cfg$output$path, sprintf("%s-taxa.csv.gz", cfg$version)))
    
      charlier::info("classification yieled %i records a loss of %i", nrow(y), nrow(x)-nrow(y))
    
    
    if (nrow(lost) > 0){
      charlier::info("lost records: %i", nrow(lost))
      lost = readr::write_csv(lost, file.path(cfg$output$path, sprintf("%s-taxa-lost.csv.gz", cfg$version)))
    }
  
  return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/taxizer.001.yaml" else args[1]
stopifnot(file.exists(cfgfile))
cfg = yaml::read_yaml(cfgfile)
if (!dir.exists(cfg$output$path)) ok = dir.create(cfg$output$path, recursive = TRUE)
charlier::start_logger(filename = file.path(cfg$output, sprintf("log-%s", cfg$version)))

charlier::info("downloading or reading NCBI taxa database")
db_tax_NCBI = taxizedb::db_download_ncbi(verbose = cfg$verbose, 
  overwrite = cfg$tax_db$overwrite) 
  

if (!interactive()){
  ok = main(cfg)
  charlier::info("done")
  quit(save = "no", status = ok)
}
