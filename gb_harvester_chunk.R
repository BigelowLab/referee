# we run this after restez fetch, build, and idorg as well as taxizedb taxizer has run
# for each database (plant, invertebrate, ...)
# read in the user's species list


main = function(cfg){
  
  on.exit({
    close(METAFILE)
    close(SEQFILE)
  })
  
  VERBOSE = !is.null(cfg$input$subsample) || interactive()

  charlier::info("starting version: %s", cfg$version)
  taxa = readr::read_csv(cfg$taxizedb$input, col_types = "c") |>
    dplyr::select(dplyr::all_of(cfg$taxizedb$taxa))
    
  idorg = read_csv(cfg$input$filename, col_types = "c")
  
  # this is a hack for using mammal instead of mammalian - for development of chunking
  if ("mammal" %in% cfg$restez$select){
    ix = idorg$group == "mammalian"
    if (any(ix)) idorg$group[ix] = "mammal"
  }
  
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
    charlier::info("there are %i idorg records available", nrow(idorg))
  }  
  
  if (cfg$restez$select != "all"){
    charlier::info("filtering to the selected group: %s", paste(cfg$restez$select, collapse = " "))
    idorg = dplyr::filter(idorg, group %in% cfg$restez$select)
  }
  
  # open metadata and sequencdata files (compressed for writing)
  # now loop through each database
  # filter the idorg for that grouping
  #  for each chunk
  #   get the records for that chunk
  #     for each record  
  #       if not NULL 
  #          save metadata 
  #          save seqdata 
  # close files
  METASEP = "\t"
  SEQSEP = ","
  DUMMY_TAXA = paste(rep(NA_character_, ncol(taxa)-1), collapse = METASEP)
  
  extract_or_na = function(record, what){
    x = try(restez::gb_extract(record, what))
    if (inherits(x, "try-error") || is.null(x)) x = NA_character_
      x
  }
  
  # Given one record, pull the requisite fields
  # @param id the accession id
  pull_record = function(rec){
    if (is.null(rec)) return(rec)
    id = extract_or_na(rec, "accession")
    if (is.na(id)){
      return(NULL)
    }
    locus = extract_or_na(rec, "locus")
    if (is.na(locus) ||  as.numeric(locus[['length']]) > cfg$restez$max_length){
      return(NULL)
    }
    #if (VERBOSE) charlier::info("working on acc_id: %s", id)
    def = extract_or_na(rec, "definition")  
    org = extract_or_na(rec, "organism")
    locus = paste(locus, collapse = " ")
    tax = dplyr::filter(taxa, species == org)
    if (nrow(tax) == 0){
      tax = DUMMY_TAXA
    } else {
      tax = dplyr::select(tax, dplyr::any_of(cfg$output$metadata)) |>
        as.matrix() |> as.vector() |>
        paste(collapse = METASEP)
    }  
    paste(c(id, org, def, locus, tax), collapse = METASEP)
  }
  

  metafile = file.path(cfg$output$path, sprintf("%s.%s.metadata.tsv", cfg$version, cfg$restez$select))
  seqfile = file.path(cfg$output$path, sprintf("%s.%s.sequence.csv", cfg$version, cfg$restez$select))
  METAFILE = file(metafile, open = "wt")
  writeLines(paste(cfg$output$metadata, collapse = METASEP), con = METAFILE)
  SEQFILE = file(seqfile, open = "wt")
  writeLines(paste(c("accession_id", "sequence"), collapse = SEQSEP), con = SEQFILE)
  
  x = dplyr::group_by(idorg, group) |>
    dplyr::group_map(
      function(tbl, key){
        if (key$group == "other"){
          charlier::info("nothing to harvest for group: %s", key$group)
          return(NULL)
        }
        charlier::info("harvesting %i records from %s database", nrow(tbl), key$group)
        restez::restez_path_set(file.path(cfg$restez$dbpath, key$group))
        
        nr = nrow(tbl)
        chunks = chunk = rep(seq_len(nr), each = cfg$restez$chunk, length.out = nr)
        nchunks = max(chunks)
        r = tbl |>
          dplyr::mutate(tbl, chunk = chunks ) |>
          dplyr::group_by(chunk)|>
          dplyr::group_walk(
            function(tab, quay){
              charlier::info("chunk %i of %i (%0.1f%%)", quay$chunk, nchunks, quay$chunk/nchunks * 100)
              REC = try(restez::gb_record_get(tab$id))
              if (inherits(REC, "try-error")) {
                charlier::error("error getting records")
                return(NULL)
              }
              rr = lapply(REC, pull_record) |> unlist() |> unname()
              writeLines(rr, con = METAFILE)
              seqs = try(restez::gb_sequence_get(tab$id))
              if (!is.null(seqs) && !inherits(seqs, "try-error")){
                seqs = paste(tab$id, seqs, sep = SEQSEP)
                writeLines(seqs, con = SEQFILE)
              }
          }) # each group
    }) # each group

    return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/gb_harvester_chunk.000.mammal.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, cfg$version))

if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}