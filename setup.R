packages = list(
  CRAN = c("rlang", "taxize", "taxizedb", "rentrez", "AnnotationBustR", "ape", "ggplot2", "restez",
           "argparser", "BiocManager", "remotes", "yaml", "stringr", "readr", "tidyr", "dplyr"),
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
dbs = c("invertebrate", "plant", "vertebrate", "mammalian", "rodent")
RESTEZ_PATHS = sapply(dbs, function(p) file.path(RESTEZ_ROOT, p) )
  

REFEREE_ROOT = readLines("~/.referee")
# source functions
ff = list.files(file.path(REFEREE_ROOT, "functions"), full.names = TRUE, pattern = "^.*\\.R$")
for (f in ff) source(f)
