#' Retrive AnnotationBustR's mtDNAterms object as a tibble
#' 
#' @return tibble ofAnnotationBustR's mtDNAterms object
mt_DNAterms = function(){
  mtDNAterms |>
    dplyr::as_tibble()
}

#' Append a data frame to an existing mtDNAterms object
#' 
#' @param x data frame (tibble) of mtDNAterms, possibly previously augmented
#' @param y data frame (tibble) of rows to append
#' @return the input \code{x} augmented by \code{y}
append_mtDNAterms = function(x = mt_DNAterms(), y = NULL){
  dplyr::bind_rows(x, y)
}

#' Compose the entrez search pattern
#'
#' If the \code{Terms} variable of \code{x} is \code{c("COI", "COX1", ..., "mt-Co1", "mt-co1")}
#' then the outpur will be \code{"AND (COI[TITL] OR COX1[TITL] ... OR mt-Co1[TITL] OR mt-co1[TITL])"}
#' @param x mtDNAterms (or an augmentaion of that)
#' @param modifier char or NULL, if char paste this after each name prior to 
#'   agg 
#' @return character string
mt_search_terms = function(x, modifier = "[TITL]"){
  terms = if (!is.null(modifier[1])) {
      x$Name
    } else {
      paste0(x$Name, modifier[1])
    }
  sprintf("AND (%s)", paste(terms, collapse = " OR "))
} 