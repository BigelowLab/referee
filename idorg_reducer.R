# For each database in ['plant', 'vertebrate', 'invertebrate] do
#   taxids = restez::list_db_ids() |>
#     restez::gb_organism_get() |>
#     some_local_reduction_function_goes_here() |>  # <--- this?
#     taxizedb::name2taxid()

main = function(cfg){
  charlier::info("starting version: %s", cfg$version)
  
  if (is.character(cfg) && (cfg[1] == "default")) cfg = default_groupings()
  
  species = readr::read_csv(cfg$input$species_list, col_types = "c") |>
     dplyr::select(dplyr::all_of(cfg$input$name)) |>
     dplyr::mutate(group = "other",
                   exact = c(TRUE, FALSE, NA)[3],
                   org = NA_character_,
                   id = NA_character_)
  charlier::info("input has %i records",nrow(species)) 
  
    
  if (cfg$input$sentence_case){
    charlier::info("making sentence case")
    species[[cfg$input$name]] <- stringr::str_to_sentence(species[[cfg$input$name]])
  }
  
  if (cfg$input$deduplicate){
    n = nrow(species)
    species = dplyr::distinct(species)
    charlier::info("deduplication removed %i records leaving %i records", nx = n - nrow(species), nrow(species))
  }

  
  # the first pass is for exact matches
  
  for (name in names(cfg$input$idorg)){
     charlier::info("extact matching input to %s idorg", name)
     idorg = readr::read_csv(cfg$input$idorg[[name]], col_types = 'c')
     mtch = match(species[[cfg$input$name]], idorg$org)
     ix = !is.na(mtch)
     charlier::info("%i exact matches", sum(ix))
     species$exact = TRUE
     species$group[ix] <- name
     species$org[ix] <- idorg$org[mtch[ix]]
     species$id[ix] <- idorg$id[mtch[ix]] 
  }
  
  # take the remaining ("other") and try for approximate matches
  # not this is repeating split-and-merge which may seem counterintuitive,
  # but at each pass we may be reducing the number of "other" labels and 
  # we are also not trying to match previous matched rows
  for (name in names(cfg$input$idorg)){
    ss = split(species, species$group)
    if ("other" %in% names(ss)){  
      charlier::info("approximate matching input to %s idorg", name)
      idorg = readr::read_csv(cfg$input$idorg[[name]], col_types = 'c')
      ss[['other']] = ss[['other']] |>
        dplyr::rowwise() |>
        dplyr::group_map(
        function(tbl, key){
           ix = agrep(tbl[[cfg$input$name]], idorg$org, ignore.case = TRUE)
           if (length(ix) > 0){
             tbl$extact = FALSE
             tbl$group = name
             tbl$org <- paste(idorg$org[mtch[ix]], collapse = ";")
             tbl$id <- paste(idorg$id[mtch[ix]], collapse = ";") 
           }
           tbl
         }) |>
      dplyr::bind_rows()
      species = dplyr::bind_rows(ss)
    }       
  }
   
  readr::write_csv(species, file.path(cfg$output$path, sprintf("%s-compact-merged.csv.gz", cfg$version)))
 
  return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/idorg_reducer.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, 
                       sprintf("%s-log", cfg$version)))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}