#' Read the OrderSeqs_Metazoan-COI or the OrderSeqs_Metazoan_rRNA_12S file
#'
#' @param filename char, the name of the file
#' @return table with 11 columns (variables)
#' \itemize{
#'   \item{species}
#'   \item{seq_header}
#'   \item{sequence}
#'   \item{seq_accession}
#'   \item{type}
#'   \item{superkingdom}
#'   \item{phylum}
#'   \item{class}
#'   \item{order}
#'   \item{species_name_id}
#'  }
read_orderseqs = function(filename = "OrderSeqs_Metazoan-COI.csv"){
  readr::read_csv(filename, col_types = readr::cols(.default = readr::col_character()))
}


