#' Compact idorg data to reduce the occurrences of org to one per file
#'
#' @param x a table of idorg as per output of idorg.R script
#' @return a table with one org per row, with one or mare taxids
compact_idorg = function(x){
  dplyr::group_by(x, org) |>
  dplyr::group_map(
    function(tbl, key){
      dplyr::mutate(key, id = paste(tbl$id, collapse = " "))
    }) |>
  dplyr::bind_rows()
}