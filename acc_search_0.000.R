# given a search names
#  for each database (plant, vertebrate, invertebrate)
#    search for species
#    search for mito

#' Convert an ids listing to a table
#' @ param named list of charcater vectors
#' @return tibble
ids_as_table = function(x){
  vals = sapply(x, paste, collapse = " ") |> unname()
  dplyr::tibble(name = names(x), ids = vals)
}



# https://www.ncbi.nlm.nih.gov/nuccore/MG512799

main = function(cfg){
  
  charlier::info("starting version %s", cfg$version)
    
  species_list = readr::read_csv(cfg$species_list$filename, col_types= "c") |>
    rlang::set_names(cfg$species_list$colname) |>
    dplyr::distinct() |>
    dplyr::mutate(db = NA_character_)
    
  if (("subsample" %in% names(cfg$species_list)) && !is.null(cfg$species_list$subsample)) {
    charlier::info("subsampling the input species_list for development")
    # subsample for the purpose of development
    # use the n as the seed to allow this to replicable 
    set.seed(cfg$species_list$subsample)
    species_list = dplyr::slice_sample(species_list, n = cfg$species_list$subsample, replace = FALSE)
  }
  
  search_term = paste0(species_list[[cfg$species_list$colname]], cfg$search$species$modifier1) #|>
    #paste(cfg$search$species$modifier2) |>
    #paste(cfg$search$species$target_modifier)
  
  charlier::info("searching for accession ids")
  ids = ncbi_accession_search(search_term) |>
      rlang::set_names(species_list[[cfg$species_list$colname]]) 
  if (cfg$fasta$dump){   
    ids_as_table(ids) |>
        readr::write_csv(file.path(cfg$output_folder, sprintf("%s-%s-ids.csv.gz", cfg$version, db_name)))
  }
  
  
  
  # Given a list with one or more named vectors of ids
  # @param x a list with one or more elements of vectors of ids
  # @return a single list with a named character vector of zero or more ids
  merge_ids = function(x){
    if ((unique(lengths(x)) |> length()) != 1){
      stop("each vector in x must have the same number of elements")
    }
    nms = names(x[[1]])
    lapply(nms,
      function(nm){
        lapply(x, getElement, nm) |>
          unlist() |>
          unique() |>
          na.omit()
      }) |>
     rlang::set_names(nms)
  }
  
  
  x = lapply(cfg$search$dbs,
    function(db_name){
      
      charlier::info("working on %s", db_name)
      
      db_path = file.path(cfg$search$dbpath, db_name)
      restez::restez_path_set(db_path)
      if (!restez::restez_ready()){
        warning("database not ready: ", db_name)
        return(NULL)
      }
      
      ix = is.na(species_list$db)
      if (!any(ix)){
        message("no more species to search for")
        return(NULL)
      }
      
      charlier::info("getting fastas")    
      ff = sapply(ids[ix], restez::gb_fasta_get, width = cfg$fasta$width, simplify = FALSE)|>
        rlang::set_names(species_list[[cfg$species_list$colname]])
      if (cfg$fasta$dump){
        charlier::info("saving fastas")
        fname = sprintf("%s-%s.fasta.gz", cfg$version, db_name)
        refdbtools::dump_fasta(ff, separate = FALSE, outpath = cfg$output_folder, filename = fname)
      }
      
      iy = length(ff) != 0
      if (any(iy)) species_list$db[which(ix)[iy]] <- db_name
      
      list(ids = ids, seq = ff)
    }) 
    
    
    # now what is to be done with the unmatched ids?
    unmatched = is.na(species_list$db)
  
  return(species_list)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/acc_search_0.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output_folder, sprintf("acc_search_log-%s", cfg$version)))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}