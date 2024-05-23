# First pass is to search for taxonomies for a uder provided species list
#
# Some taxonomies mayeb be unkown at `order` level, so we try to fill those in 
#  with search_order_missing()
#   





#' The primary script runner
#'
#' @param cfg list the configuration list
#' @param key char, the entrez key
main = function(cfg = refdbtools::read_configuration("input/egrey0.000.yaml"),
                entrez_key = refdbtools::get_entrez_key()){
  charlier::info("starting version %s", cfg$version)
  
  charlier::info("taking care of preliminaries")
  rentrez::set_entrez_key(entrez_key)
  
  mtDNAterms = append_mtDNAterms(x = mt_DNAterms(), 
    y = dplyr::as_tibble(cfg$mtDNAterms))
  
  is_mtgene = cfg$locus %in% cfg$mtgene_loci
  
  target_locus_synonyms = mtDNAterms |>
    dplyr::filter(Locus %in% cfg$locus)
  
  search_terms = mt_search_terms(target_locus_synonyms, 
    modifier = cfg$entrez$mt_search$search_modifier)
    
  species_list = readr::read_csv(cfg$species_list$filename, col_types= "c") |>
    rlang::set_names(cfg$species_list$colname)
    
  if (("subsample" %in% names(cfg$species_list)) && !is.null(cfg$species_list$subsample)) {
    charlier::info("subsampling the input species_list for development")
    # subsample for the purpose of development
    # use the n as the seed to allow this to replicable 
    set.seed(cfg$species_list$subsample)
    species_list = dplyr::slice_sample(species_list, n = cfg$species_list$subsample, replace = FALSE)
  }
  
  order_list = readr::read_csv(cfg$order_list$filename, col_types = "ccccccc")
  
  species_list_dedup <- unique(species_list[[cfg$species_list$colname]])
  
  charlier::info("downloading or reading NCBI taxa database")
  db_tax_NCBI = taxizedb::db_download_ncbi(verbose = cfg$verbose, 
    overwrite = cfg$tax_db$ncbi$overwrite) 
  
  charlier::info("obtaining fuller taxa classifications for user's species_list")
  # this uses the downloaded db by default and mines a list
  # here we convert it to a data frame which we can operate upon by group (species in this case)
  # I'm saving a copy here, in anticipation of needing restarts later (maybe just for development)
  taxonomies_cls_filename = file.path(cfg$output_folder, sprintf("%s-taxonomies_cls.csv.gz", cfg$version))
  taxonomies_cls <- if (file.exists(taxonomies_cls_filename)){
    readr::read_csv(taxonomies_cls_filename, col_types = "cccc")
    } else {
      taxizedb::classification(species_list_dedup, db="ncbi") |>
        reform_classification() |>
        dplyr::mutate(name = gsub(".", "", .data$name, fixed = TRUE)) |>
        readr::write_csv(taxonomies_cls_filename)
    } 
    
  charlier::info("tabulating classification taxa")
  taxa_df = taxonomies_cls |>
    dplyr::mutate(species = factor(.data$species, levels = species_list_dedup)) |>
    tabulate_classification()
    
    
  charlier::info("joining taxa classifications for user's species_list")
  # here we join the users species list with complete taxa found by taxizedb
  # NONPROGRAMMATIC - see the by= argument
  a01_NAMES = dplyr::left_join(species_list, taxa_df, by = dplyr::join_by(search_name == tax_query))
  no_species = is.na(a01_NAMES$species)
  a01_NAMES_missing = a01_NAMES |>
    dplyr::filter(no_species)  |>
    readr::write_csv("data/a01_NAMES_withoutTaxonomy.csv.gz")
  a01_NAMES = a01_NAMES |>
    dplyr::filter(!no_species) |>
    readr::write_csv("data/a01_NAMES_wTaxonomy.csv.gz")
    
  
  #charlier::info("searching with entrez_search for cases where order is missing")
  #orders_missing = order_list |>
  #  dplyr::filter(!(order %in% a01_NAMES$order))
  #  # this gets us through lines 253 in Erin's
  
  
  # determined by cfg$locus - make programmatic
  #order_seqs = read_orderseqs("data/orderseqs/OrderSeqs_Metazoan-COI.csv")
  
  # skip to Erin's 303
  searchterms = paste(a01_NAMES$search_name, cfg$entrez$species_search$search_modifier1)
  seqs = sequence_search_and_fetch(searchterms)
  searchterms = paste(search_pattern, cfg$entrez$species_search$search_modifier1)
  seqs_mito = sequence_search_and_fetch(searchterms)
  
    
    
  return(0)
} # end of main

source("setup.R")
data(mtDNAterms)
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/egrey0.000.yaml" else args[1]
keyfile = if (length(args) <= 1) "~/.entrez_key" else args[2]
cfg = refdbtools::read_configuration(cfgfile)
entrez_key = refdbtools::get_entrez_key(keyfile)
charlier::start_logger(filename = file.path(cfg$output_folder, sprintf("log-%s", cfg$version)))
status = main(cfg, entrez_ey = entrez_key)

if (!interactive()) quit(status = status, save = "no")
