# Use this to fetch and then build one or more restez databases
#
# Run as a script from shell providing the input YAML

suppressPackageStartupMessages({
  library(charlier)
  library(restez)
}

cfgfile = commandArgs(trailingOnly = TRUE)
if (length(cfgfile) == 0 || nchar(cfgfile) == 0){
  cfgfile = "/mnt/storage/data/edna/refdb/restez/restez_fetch_and_build.000.yaml"
}

restez_root = cfg$restez$root_path
logfile = file.path(restez_root, sprintf("%s-log.txt", cfg$version))

charlier::start_logger(filename = logfile)

dbs = cfg$resetz$dbs

charlier::info("fetching databases: %s", names(dbs))
for (db in names(dbs)){
  charlier::info("fetching data for %s", db)
  db_path = file.path(restez_root, db)
  if (!dir.exists(db_path)) dir.create(db_path, recursive = TRUE)
  restez::restez_path_set(db_path)
  ok = try(restez::db_download(preselection = dbs[[db]], 
                               overwrite = cfg$restez$overwrite, 
                               max_tries = cfg$restez$max_tries))
  if (inherits(ok, "try_error")){
    charlier::error("unable to fetch the data")
    cat(ok, sep = "\n", file = logfile, append = TRUE)
  } else (!ok){
    charlier::warning("unable to fetch the data")
  } else {
    charlier::info("successfully fetched data for %s", db)
  }
}

for (db in names(dbs)){
  charlier::info("building database for %s", db)
  db_path = file.path(restez_root, db)
  if (!dir.exists(db_path)) dir.create(db_path, recursive = TRUE)
  restez::restez_path_set(db_path)
  restez::db_delete()
  ok = try(restez::db_create(max_length = cfg$restez$max_length))
  if (inherits(ok, "try-error")){
    charlier::error("unable to build database")
    cat(ok, sep = "\n", file = logfile, append = TRUE)
  }} else {
    charlier::info("successfully built database for %s", db)
  }
}

charlier::info("Done!")
quit(status = 0, save = "no")

# 2024-06-06 BT
# > restez::db_download()
# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Looking up latest GenBank release ...
# ... release number 260
# ... found 10388 sequence files
# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Which sequence file types would you like to download?
# Choose from those listed below:
# • 1  - 'Invertebrate'
#         2561 files and 1080 GB
# • 2  - 'Plant (including fungi and algae)'
#         2458 files and 1630 GB
# • 3  - 'Bacterial'
#         1201 files and 533 GB
# • 4  - 'Viral'
#         1095 files and 484 GB
# • 5  - 'EST (expressed sequence tag)'
#         579 files and 244 GB
# • 6  - 'Other vertebrate'
#         575 files and 243 GB
# • 7  - 'Other mammalian'
#         349 files and 136 GB
# • 8  - 'Rodent'
#         343 files and 139 GB
# • 9  - 'GSS (genome survey sequence)'
#         270 files and 117 GB
# • 10 - 'Patent'
#         269 files and 114 GB
# • 11 - 'Constructed'
#         240 files and 101 GB
# • 12 - 'TSA (transcriptome shotgun assembly)'
#         127 files and 54.2 GB
# • 13 - 'Environmental sampling'
#         95 files and 41.3 GB
# • 14 - 'Primate'
#         87 files and 35.7 GB
# • 15 - 'HTGS (high throughput genomic sequencing)'
#         82 files and 36.8 GB
# • 16 - 'Synthetic and chimeric'
#         30 files and 12.2 GB
# • 17 - 'STS (sequence tagged site)'
#         11 files and 4.45 GB
# • 18 - 'HTC (high throughput cDNA sequencing)'
#         8 files and 3.49 GB
# • 19 - 'Phage'
#         7 files and 3.32 GB
# • 20 - 'Unannotated'
#         1 files and 0.00732 GB
# 