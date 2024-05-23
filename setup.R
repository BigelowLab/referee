packages = list(
  CRAN = c("rlang", "taxize", "taxizedb", "rentrez", "AnnotationBustR", "ape", "ggplot2", "restez",
           "argparser", "BiocManager", "remotes", "yaml", "stringr", "dplyr", "readr", "tidyr"),
  bioc = c("Biostrings", "genbankr"),
  github = c("charlier" = "BigelowLab", "refdbtools" = "BigelowLab")
)

# manage installations as needed
installed = installed.packages() |> rownames()
for (pkg in packages$CRAN){
  if (!pkg %in% installed) install.packages(pkg, repos = "https://cloud.r-project.org/", update = FALSE)

}
for (pkg in packages$bioc){
  if (!pkg %in% installed) BiocManager::install(pkg, update = FALSE)

}
for (pkg in names(packages$github)){
  if (!pkg %in% installed) remotes::install_github(file.path(packages$github[pkg], pkg), update = FALSE)
}

# load packages from library
suppressPackageStartupMessages({
  for (p in packages$CRAN) library(p, character.only = TRUE)
  for (p in packages$bioc) library(p, character.only = TRUE)
  for (p in names(packages$github)) library(p, character.only = TRUE)
})

RESTEZ_ROOT = "/mnt/storage/data/edna/refdb/restez"
paths = c("invertebrate" = "invertebrate",
          "plant" = "plant_with_fungi_algae",
          "vertebrate" = "other_vertebrate") 
RESTEZ_PATHS = sapply(names(paths), function(p) file.path(RESTEZ_ROOT, paths[p]) )
  


# source functions
ff = list.files("functions", full.names = TRUE, pattern = "^.*\\.R$")
for (f in ff) source(f)
