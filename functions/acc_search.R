#' Accession search function for one or more search terms
#'
#' This is a wrapper of \code{\link[restez]{ncbi_acc_get}}
#'
#' @param searchterms char, one or more accession IDs
#' @param ... other arguments for \code{\link[restez]{ncbi_acc_get}}
#' @return character vector of one or more accession IDs
ncbi_accession_search = function(searchterms, ...){
  sapply(searchterms, restez::ncbi_acc_get, ...)
} 

#' Fetch sequences by accession ID
#'
#' This is a wrapper of \code{\link[restez]{gb_fasta_get}}
#'
#' @param ids char, one or more accession ids
#' @param ... other agruments for \code{\link[restez]{gb_fasta_get}}
#' @return named vector of one or more sequences (FASTA)
gb_sequence_fetch = function(ids, ...){
  restez::gb_fasta_get(ids, ...)
}

#' Retrieve sequences for one or more search terms
#' 
#' @param searchterms char, one or more search terms
#' @param ... other arguments for \code{\link[restez]{ncbi_acc_get}} and
#'   \code{\link[restez]{gb_fasta_get}}
#' @return data.frame (tibble) of searchterm, id and fasta-seq
sequence_search_and_fetch = function(searchterms, ...){
  
  restez::ncbi_acc_get(searchterms, ...) |>
    restez::gb_fasta_get(ids, ...)
}
