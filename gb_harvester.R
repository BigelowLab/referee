# we run this after restez fetch, build, and idorg as well as taxizedb taxizer has run
# for each database (plant, invertebrate, ...)
# read in the user's species list


main = function(cfg){
  
  on.exit({
    close(METAFILE)
    close(SEQFILE)
  })
  
  VERBOSE = !is.null(cfg$input$subsample)

  charlier::info("starting version: %s", cfg$version)
  taxa = readr::read_csv(cfg$taxizedb$input, col_types = "c") |>
    dplyr::select(dplyr::all_of(cfg$taxizedb$taxa))
    
  idorg = read_csv(cfg$input$filename, col_types = "c")
  # we can't know if we have the compact form, so test if there is an space in the first
  # number of ids
  if (any(grepl(" ", idorg$id[seq_len(cfg$input$n_compact_test)], fixed = TRUE))){
    idorg = tidyr::separate_longer_delim(idorg, dplyr::all_of("id"), delim = " ")
  }
  
  if (!is.null(cfg$input$subsample)) {
    charlier::info("subsampling to just %i idorg records out of %i records", cfg$input$subsample, nrow(idorg))
    set.seed(cfg$input$subsample)
    # we group and the sample twice so that every group is sampled
    idorg = idorg |>
      dplyr::group_by(group) |>
      dplyr::slice_sample(n = cfg$input$subsample, replace = FALSE) |>
      dplyr::ungroup() |>
      dplyr::slice_sample(n = cfg$input$subsample, replace = FALSE)
  } else {
    charlier::info("there are %i taxids available", length(taxids))
  }  
  
  if (cfg$restez$select != "all"){
    idorg = dplyr::filter(idorg, group %in% cfg$restez$select)
  }
  
  # open metadata and sequencdata files (compressed for writing)
  # now loop through each database
  # filter the idorg for that grouping
  # get the record 
  #   if not NULL 
  #      save metadata 
  #      save seqdata 
  # close files

  extract_or_na = function(record, what){
    x = restez::gb_extract(record, what)
    if (is.null(x)) x = NA_character_
      x
  }

  metafile = file.path(cfg$output$path, sprintf("%s.metadata.tsv.gz", cfg$version))
  seqfile = file.path(cfg$output$path, sprintf("%s.sequence.csv.gz", cfg$version))
  METAFILE = gzfile(metafile, open = "wt")
  writeLines(paste(cfg$output$metadata, collapse = ","), con = METAFILE)
  SEQFILE = file(seqfile, open = "wt")
  x = dplyr::group_by(idorg, group) |>
    dplyr::group_map(
      function(tbl, key){
        if (key$group == "other"){
          charlier::info("nothing to harvest for group: %s", key$group)
          return(NULL)
        }
        charlier::info("harvesting %i records from %s database", nrow(tbl), key$group)
        restez::restez_path_set(file.path(cfg$restez$dbpath, key$group))
        r = dplyr::rowwise(tbl)|>
          dplyr::group_walk(
            function(tab, quay){
              rec = restez::gb_record_get(tab$id)
              if (!is.null(rec)){
                if (VERBOSE) cat(tab$id, "\n")
                def = extract_or_na(rec, "definition")  
                org = extract_or_na(rec, "organism")
                locus = extract_or_na(rec, "locus") |>
                  paste(collapse = " ")
                tax = dplyr::filter(taxa, species == org)
                if (nrow(tax) == 0){
                  tax = paste(rep(NA_character_, ncol(taxa)-1), collapse = ",")
                } else {
                  tax = dplyr::select(tax, dplyr::any_of(cfg$output$metadata)) |>
                    as.matrix() |> as.vector() |>
                    paste(collapse = ",")
                }
                writeLines(paste(c(tab$id, org, def, dQuote(locus), tax), collapse = ","), con = METAFILE)
                seq = restez::gb_extract(rec, "sequence")
                if (!is.null(seq)){
                  writeLines(paste(c(tab$id, seq), collapse = ","), con = SEQFILE)
                }
              } # record is not null?
          }) # each row
    }) # each group

    return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/gb_harvester.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, cfg$version))

if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}