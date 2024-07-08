#' Transform metadata so that it is consistently tab delimited (oops).
#' 
#' THis is a very simple (mindless?) search for "short" rows where I accidentally
#' separated with commas rather than tabs for some of the columns.  Fortunately the
#' errant columns are at the end of each row. 
#' 
#' @param filename name of the file to read
#' @param tibble with "short" rows NA padded
transform_metadata = function(filename = "~/Downloads/gb_harvester.000.invertebrate.metadata.tsv"){
  SS = readLines(filename) |>
    lapply(function(s) strsplit(s, "\t")[[1]])
  nSS = lengths(SS)
  nHDR = nSS[1]
  keepindex = 1:4
  for (i in seq_len(length(SS))){
    #fix the known bads only
    if (nSS[i] == 5){
      SS[[i]] = c(SS[[i]][keepindex], strsplit(SS[[i]][[5]], ",")[[1]])
      nSS[i] = length(SS[[i]])
    } 
    if (nSS[i] < nHDR){
      n = nHDR - nSS[i]
      SS[[i]] = c(SS[[i]], rep(NA_character_, n)) 
      nSS[i] = length(SS[[i]])
    }
  }
  
  x = do.call(rbind,SS)
  colnames(x) <- x[1,]
  dplyr::as_tibble(x[-1,])
}