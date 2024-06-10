# Use this to build one or more restez databases
#
# Run as a script from shell providing the input YAML

suppressPackageStartupMessages({
  library(charlier)
  library(restez)
})

cfgfile = commandArgs(trailingOnly = TRUE)
if ((length(cfgfile) == 0) || (nchar(cfgfile) == 0)){
  cfgfile = "/mnt/storage/data/edna/refdb/restez/restez_build_db.000.yaml"
}

cfg = charlier::read_config(cfgfile)

restez_root = cfg$restez$root_path
logfile = file.path(restez_root, sprintf("%s-log.txt", cfg$version))

charlier::start_logger(filename = logfile)

dbs = cfg$restez$dbs |> unlist()

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
  } else {
    charlier::info("successfully built database for %s", db)
  }
}

charlier::info("Done!")
quit(status = 0, save = "no")

