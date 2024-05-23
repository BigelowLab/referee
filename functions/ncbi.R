#' Search for species with rentrez::search()
#'
#' @param x data frame of species info
#' @param cfg list, configuartion list
#' @param target_search_term chr, the target search term
#' @return
search_species = function(x, cfg, 
  target_search_term = "AND (COI OR COX1 OR cox1 OR CO1 OR COXI OR cytochrome c oxidase subunit I OR COX-I OR coi OR MT-CO1 OR mt-Co1 OR mt-co1)"){
  
  search_species_one = function(tbl, key, cfg = NULL,
                                target_search_term = character()){

    search_name <- paste0(tbl$search_name ,cfg$entrez$species_search$search_modifier1)
    search_term <- paste(search_name, target_search_term, collapse = " ")
    term = paste(search_name, cfg$entrez$species_search$search_modifier2)
    mitogenomes =  try(rentrez::entrez_search(db=cfg$entrez$species_search$db, 
                                             term = term, 
                                             retmax = cfg$entrez$species_search$retmax))
      if (!inherits(mitogenomes, "try-error")){
        n_mitogenomes = mitogenomes$count
        ids_mitogenomes = paste(mitogenomes$ids, collapse="|")
        targets = try(rentrez::entrez_search(db=cfg$entrez$species_search$db, 
                                      term = search_term, 
                                      retmax = cfg$entrez$species_search$retmax))
        if (!inherits(targets, "try-error")){
          n_targets <- targets$count
          ids_target <- paste(targets$ids, collapse="|")
        } else {
          n_targets = NA_real_
          ids_target = NA_character_
        }
        
      } else {
        n_mitogenomes = NA_real_
        ids_mitogenomes = NA_character_
        n_targets = NA_real_
        ids_target = NA_character_
      }
      Sys.sleep(cfg$entrez$species_search$sleep)
      dplyr::mutate(tbl,
        n_mitogenome = n_mitogenomes,
        ids_mitogenomes = ids_mitogenomes,
        n_target = n_targets,
        ids_target = ids_target
        )
  }
  
  x |>
    dplyr::rowwise() |>
    dplyr::group_map(search_species_one, .keep = TRUE, cfg = cfg) |>
    dplyr::bind_rows()
}


# for each row of orders_missing
#   species_ids_ls = series of codes
#   if (the first code is NA) return NULL
#   if (the length of codes is <= 3)
#     for each code
#       mitogenomes = search1()
#       if (!error)
#         if (one or more returned mitogenomes)
#           mito_id = sample one mitogenomes$id
#           assemble and return df
#       endif else 
#         targets = search2()
#         if (!error)
#           return
#   else if (the length of codes is > 3)
#     species_ids = randomize the codes
#     finds = 0
#     ss = list()
#     for each species_ids
#       mitogenomes = search3()
#       if (!error)
#          mito_id <- sample(mitogenomes$ids,1)
#          append df to ss
#          increment finds
#       else
#         targets = search4()
#         if (!error)
#           append df to ss
#           increment finds
#     until finds == 3
#     return df

#' Find up to 3 mitogenomes or target sequences for missing orders.   
#'
#' @param x data frame, the listing of orders that were missing 
#' @param cfg list, the configuration list
#' @param target_search_term str, pattern used for \code{term} when the initial search for the order fails
#' @param verbose logical, if TRUE output helpful messages (for development really)
#' @return a data frame (tibble) of search results
search_order_missing = function(x, cfg, 
  target_search_term = "AND (COI OR COX1 OR cox1 OR CO1 OR COXI OR cytochrome c oxidase subunit I OR COX-I OR coi OR MT-CO1 OR mt-Co1 OR mt-co1)",
  verbose = FALSE){
  
  keep = c("superkingdom", "kingdom", "phylum", "class", "order")
  # we add and id for housekeeping
  x = dplyr::mutate(x, id = seq_len(nrow(x)))
  NX = nrow(x)
  
  # this is the function that accpts 1 row of \code{x} and attempts to more fully populate
  
  search_order_one = function(tbl, key){
    if (verbose) cat("[search_order_missing]", sprintf("%i of %i", tbl$id, NX), 
                      substring(tbl$full_branch,1,60), "...\n")
    species_ids_ls <- strsplit(tbl$spp_list, ";", fixed = TRUE)[[1]]
    if (is.na(species_ids_ls[1])) return(NULL)
    ss = list()
    if (length(species_ids_ls) <= 3){
      species_ids = species_ids_ls
      ss = lapply(species_ids_ls,
        function(id){
          
          ### FIRST TRY
          search_name = paste0("txid", id, "[Organism]")
          term1 = paste(search_name, "AND mitochondrion[TITL] AND complete genome[TITL]")
          mitogenomes <- try(rentrez::entrez_search(db=cfg$entrez$order_search1$database, 
                                                    term = term1, 
                                                    retmax=cfg$entrez$order_search1$retmax,
                                                    use_history = TRUE))
          if (!inherits(mitogenomes, "try-error")){
            if (length(mitogenomes$ids) > 0){  
              mito_id <- sample(as.character(mitogenomes$ids),1) #choose a random mitogenome for this species
              r <- dplyr::select(dplyr::all_of(keep)) |>
                dplyr::mutate(
                  species_id = id, 
                  ids_mitogenome = mito_id, 
                  ids_target = NA_character_)
              Sys.sleep(cfg$entrez$order_search1$sleep)
              return(r)
            } else {
              ### SECOND TRY
              if (verbose) cat("mitogenomes search failed with term1")
              term2 = paste(search_name, target_search_term, collapse = " ")
              targets <- try(rentrez::entrez_search(db = cfg$entrez$order_search2$database, 
                                                    term = term2, 
                                                    retmax = cfg$entrez$order_search2$retmax,
                                                    use_history = TRUE))
                if (!inherits(targets, "try-error")){
                  cat(str(targets), "\n")
                  if ((length(targets) > 0) && (length(targets[["id"]]) > 0)){
                    target_id <- sample(as.character(targets[["id"]]),1)
                    r <- dplyr::select(dplyr::all_of(keep)) |>
                      dplyr::mutate(
                        species_id = id, 
                        ids_mitogenome = NA_character_, 
                        ids_target = target_id)
                    Sys.sleep(cfg$entrez$order_search2$sleep)
                    return(r)
                  }
                } else {
                  if (verbose)cat("mitogenomes search failed with term2")
                }
            }  # try targets
          } # mitogenome error?
        }) # lapply over species_ids_ls
     } else {  # length of species_ids_ls > 3
       species_ids <- sample(as.character(species_ids_ls), length(species_ids_ls), replace = FALSE) 
       finds = 0
       finds_max = 3
       ss = vector(mode = "list", length = finds_max)
       for (id in species_ids){
         search_name <- paste0("txid",id,"[Organism]")
         term3 = paste(search_name, "AND mitochondrion[TITL] AND complete genome[TITL]")
         mitogenomes <- try(rentrez::entrez_search(db = cfg$entrez$order_search3$database, 
                                                        term = term3, 
                                                        retmax = cfg$entrez$order_search3$retmax,
                                                        use_history = TRUE))
         if (!inherits(mitogenomes, "try-error")){
           if (length(mitogenomes$ids)>0) {
             mito_id <- sample(as.character(mitogenomes$ids),1)
             r <- dplyr::select(dplyr::all_of(keep)) |>
               dplyr::mutate(
                 species_id = id, 
                 ids_mitogenome = mito_id, 
                 ids_target = NA_character_)
             finds=finds+1
             ss[finds] = r
             Sys.sleep(cfg$entrez$order_search3$sleep)
           } else {
             term4 = paste(search_name, target_search_term, collapse = " ")
             targets = try(rentrez::entrez_search(db = cfg$entrez$order_search4$database, 
                                                       term = term4, 
                                                       retmax = cfg$entrez$order_search4$retmax,
                                                       use_history = TRUE))
                                                       
             if (!inherits(targets, "try-error") && (length(targets) > 0 ) && (length(targets[["id"]])>0)) {
               target_id = sample(as.character(targets[["id"]]), 1) 
               r <- dplyr::select(dplyr::all_of(keep)) |>
                 dplyr::mutate(
                   species_id = id, 
                   ids_mitogenome = NA_character_, 
                   ids_target = target_id)
               finds = finds + 1
               ss[finds] = r
               Sys.sleep(cfg$entrez$order_search4$sleep)             
            }
           
           } # mito or target?
         } # error?
         if (finds >= 3) break
       } # id loop
       
     } # search_order_one
     
     
     r = dplyr::bind_rows(ss)
     if (verbose) cat("  found", nrow(r), "records\n")
  }
  
  dplyr::rowwise(x) |>
    dplyr::group_map(search_order_one, .keep = TRUE) |>
    dplyr::bind_rows()
  
} # search_order_missing




#' Get taxonomy for each species representative for the missing orders.
taxize_order_missing = function(){
  
} # taxize order missing