# referee
Scripts for building reference databases for Maine eDNA project

Here we store **scripts** and ancillary **functions** for building reference databases. **Data** is stored elsewhere.  

All scripts are run with a configuration input - we have chosen [YAML as the configuration format](https://github.com/BigelowLab/charlier/wiki/Configurations). 

## Workflow scripts

  + `idorgs` mines the genbank databasii (plant, vertebrate, invertebrate) for taxa id and organism name(s)
  
  + `taxizer` attempts to populate a complete taxonomy with IDs for a provided species list
  
  + `fastah` attempts to building a FASTA file of reference sequences for species with IDs
  
## Code organization

Scripts live at the top level (possibly witha companion PBS submission shell script).  Each of these `source` the `setup.R` file which handles package installation and sourcing ancilalry functionality.  Ancillary functionaltiy resides in the the `functions` subdirectory.

### Script organization

Each script is organized roughly like this to make interactive development easy (on the developer!) by providing a default input configuration file path and burying the code steps in a `main()` function that accepts just one argument, the configuration list.

```
main = function(cfg){
  charlier::info("starting version: %s", cfg$version)
  # do stuff here
  return(0 or non-zero)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "/some/path/to/a/default/config.yaml" else args[1]
cfg = refdbtools::read_configuration(cfgfile)
charlier::start_logger(filename = file.path(cfg$output$path, cfg$version))
if (!interactive()){
  ok = main(cfg)
  charlier::info("done!")
  quit(save = "no", status = ok)
}
```
  
> Fun fact!  Ben would like it if all true scripts used the extension `.Rscript` instead of `.R`.  But nobody asked Ben.
  
### Function organization

Functions are small reueseable bits of code (atoms!) that are assembled into a logical order in the scripts (molecules!).  This style of coding is often called modular or atomistic (hence the atoms-molecule paradigm).  99% of the time functions do not invoke the `library` or `require` function - put any of those in either the `setup.R` script (preferred) **or** under rare circumstances in the script you are running.   Currently, functions are gathered into text files, with the `.R` extension, into groupings around either a workflow/task or around a particular package.

### Function documentation

We use the [Roxygen](https://roxygen2.r-lib.org/) style of documenting functions.  This style has us prepending documentation lines with `#'` and using the `@keyword` style of flagging arguments, ntes, return values, etc.  Starting this way makes for very consistent documentation and an easy transition to building a package.  Here is an example...

```
#' Like isTRUE and isFALSE but for vectors
#' 
#' @param x logical vector with or without NAs
#' @param na.rm logical, if TRUE remove NAs before consideration
#' @return logical vector
is_false = function(x = c(TRUE, FALSE, NA), na.rm = FALSE){
  sapply(x, isFALSE)
}
```

## Vocabulary
  
Accession ID:

Taxa ID:
  
  