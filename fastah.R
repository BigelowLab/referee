# given the output of idorg_reducer (compact) iteratively retrieve available 
# FASTA records. The input should have the following form where
# species and group are provided and id has zero or more accession ids (to be split)
# #  A tibble: 18,039 × 5
#    species                group        exact org                    id          
#    <chr>                  <chr>        <lgl> <chr>                  <chr>       
#  1 Actias luna            invertebrate TRUE  Actias luna            KC170540 KC…
#  2 Notodonta scitipennis  invertebrate TRUE  Notodonta scitipennis  KC189982 KC…
#  3 Egira dolosa           invertebrate TRUE  Egira dolosa           KC193646 KC…
# 
# To this we add a column nfasta which records how many FASTA records were retrieved and saved
# 
# We write to a file that is kept open during the process. All retrieved records are saved in that
# file regardless of the group.

main = function(cfg){
  
  x = readr::read_csv(cfg$input$filename, col_types = "c")
  if (!is.null(cfg$input$subsample)){
    charlier::info("subsampling to %i from %i records", cfg$input$subsample, nrow(x))
    set.seed(cfg$input$subsample)
    x = dplyr::slice_sample(x, n = cfg$input$subsample, replace = FALSE)
  }
  charlier::info("working with %i records", nrow(x))
  
  x = dplyr::mutate(x, nfasta = 0, .before = id)
  outfile = file.path(cfg$output$path, sprintf("%s.fasta", cfg$version))
  CONN = file(outfile, open = 'wt')
  x = dplyr::group_by(x, group) |>
    dplyr::group_map(
      function(grp, key){
        # nothing to do if group is 'other'
        if (grp$group[1] == "other") return(grp)
        charlier::info("group %s has %i records",grp$group[1], nrow(grp))
        restez::restez_path_set(file.path(cfg$restez$dbpath, grp$group[1]))
        # otherwise we go row-by-row harvesting FASTAs
        dplyr::rowwise(grp) |>
        dplyr::group_map(
          function(tbl, key){
            id = tbl$id
            if (is_nullna(id)) return(tbl)
            ids = strsplit(id, " ")[[1]]
            ff = restez::gb_fasta_get(id = ids, width = cfg$output$width)
            if (!is.null(ff)){
              writeLines(ff, CONN, sep = "")
              tbl$nfasta = length(ff)
            }
            return(tbl)
         }) |>
        dplyr::bind_rows()
         }, .keep = TRUE) |>
    dplyr::bind_rows() |>
    readr::write_csv(file.path(cfg$output$path, sprintf("%s-idorg.csv.gz", cfg$version)))
    close(CONN)
    return(0)
}

source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "/mnt/storage/data/edna/mednaTaxaRef/egrey/input/fastah.000.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, sprintf("fastah-%s", cfg$version)))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}