#' The default groupings and filters
#'
#' @return a list of groupings where the only element,  named "groupings", is itself
#'  a list
default_groupings = function(){
  list(groupings = list(
      plant = list(dbname = "plant", 
          note = "any species in [Kingdom==Plantae]", 
          filter = list(kingdom = c("Plantae", "Viridiplantae"))), 
      invertebrate = list(dbname = "invertebrate", 
          note = "any species in [Kingdom==Metazoa and Class != Vertebrata]", 
          filter = list(kingdom = "Metazoa", class = "-Vertebrata")), 
      vertebrate = list(dbname = "vertebrate", 
          note = "any species in [Kingdom==Metazoa and Class == Vertebrata]", 
          filter = list(kingdom = "Metazoa", class = "Vertebrata")), 
      other = list(dbname = NULL, 
          note = "any species in [Kingdom != Metazoa and Kingdom != Plantae]", 
          filter = list(kingdom = "-Metazoa", kingdom = "-Plantae"))))
}

#' Assign rows of taxonomy to broad groupings
#'
#' @param x a table of taxonomy as per taxizer output
#' @param cfg configuration list
#' @param default char, the default group name, used also to 
#'  identify the desired groups in the configuration
#' @return the input table with an added 'group' column
group_taxa = function(x, cfg = "default", 
  default = "other"){
  
  if (is.character(cfg) && (cfg[1] == "default")) cfg = default_groupings()
  
  x = dplyr::mutate(x, group = default)
  
  groups = names(cfg$groupings)
  groups = groups[!(groups %in% default)]
  for (g in groups){
    # iterate over the different specified levels (kingdom, class, etc)
    ix = sapply(names(cfg$groupings[[g]]$filter),
      function(tx){
        vals = cfg$groupings[[g]]$filter[[tx]]
        isneg = grepl("-", substring(vals, 1,1), fixed = TRUE)
        vals[isneg] = substring(vals[isneg], 2)
        # iterate over one or more values to match against at this level
        sapply(seq_along(vals),
          function(i){
            if (isneg[i]){
              r = !(x[[tx]] == vals[i])
            } else {
              r = x[[tx]] == vals[i]
            }
            r
          })|>
          apply(1, any_true)  # <- this means we are ORing
      }) |>
      apply(1, all_true)
    x$group[ix] <- g
    
  }
  x
}

#' Reformat a \code{taxizedb::classification()} output into a tibble.
#'
#' For each request \code{taxizedb::classification()} it returns a list element
#' what has either three variable data frame (name, rank and id) or NA (instead of
#' a friendlier empty data frame or NULL)
#'
#' @param x named list as output by \code{taxizedb::classification()}
#' @return a tibble with a prepended \code{species} variable for each element of \code{x}
reform_classification = function(x){
  dummy = dplyr::tibble(name = NA_character_, rank = NA_character_, id = NA_character_)
  lapply(names(x),
    function(sp){
      v = if (is.na(x[sp])){
          dummy
        } else {
          dplyr::as_tibble(x[[sp]])
        } 
      dplyr::mutate(v, species = sp, .before = 1)
    }) |>
  dplyr::bind_rows()
}

#' Tally species in the output of \code{reform_taxized}
#'
#' @param x data frame (tibble), the output of \code{reform_taxized}
#' @param ranks the order ranks to tally
#' @param sep char, the character separator used to bind \code{name} and \code{id}
#' @param split_id, logical, if TRUE split the ID from the rank values
#' @return data frame (tibble) of ranks by species
tabulate_classification = function(x, 
  ranks = c("superkingdom", "kingdom", "phylum", "class", 
            "order", "family", "genus", "species"),
            sep = "_",
            split_id = TRUE){
              
   dummy = dplyr::tibble(
     tax_query = NA_character_,
     superkingdom = NA_character_,
     kingdom = NA_character_,
     phylum = NA_character_,
     class = NA_character_,
     order = NA_character_,
     family = NA_character_,
     genus = NA_character_,
     species = NA_character_
     )  
              
   tally_one = function(tbl, key, dummy = NULL){
     
     first = function(x){
       x[1]
     }
     
     if (tbl$value[1] == "NA_NA"){
       v = dummy |>
         dplyr::mutate(tax_query = tbl$tax_query)
     } else {
     
        v = dplyr::filter(tbl, rank %in% ranks) |>
          tidyr::pivot_wider(id_cols = tax_query, 
                             names_from = rank, 
                             values_from = value,
                             values_fn = first,
                             names_repair = "minimal")
      }
      v
   } # tally_one
   
   
   
   x = x |>
    dplyr::mutate(value = paste(.data$name, .data$id, sep = sep)) |>
    dplyr::rename(tax_query = "species") |>
    dplyr::group_by(tax_query) |>
    dplyr::group_map(tally_one, .keep = TRUE, dummy = dummy) |>
    dplyr::bind_rows()  
  
  if (split_id){
    x =split_taxa_ids(x)
  }  
   
  x          
}


#' Split a table with taxa_id into 2-column taxa, id
#'
#' @param x a table such as produced by tabulate_classification
#' @param taxa char, the taxa to split
#' @ param sep char, the character used to separate taxa_id
#' @return a wider table with IDs split from taxa
split_taxa_ids = function(x,
  taxa = c("superkingdom", "kingdom", "phylum", "class", "order", "family", "genus", "species"),
  sep = "_"){
    
    for (nm in taxa){
      x = tidyr::separate(x,
        dplyr::any_of(nm),
        sep = sep, 
        into = c(nm, paste0(nm, "_id")))
    }
    
   x 
  }
