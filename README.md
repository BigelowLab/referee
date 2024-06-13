# referee
Scripts for building reference databases for Maine eDNA project

Here we store **scripts** and ancillary **functions** for building reference databases. **Data** is stored elsewhere.  

All scripts are run with a configuration input - we have chosen [YAML as the configuration format](https://github.com/BigelowLab/charlier/wiki/Configurations). 


# Code

All coding environments can, for now, be established by using `source()` on a special setup script cleverly named `setup.R`.   You **must** create a special hidden file that helps this code suite know where to find source code.  Use this command in R to set that up for your user.

```
cat("/some/path/to/the/referee/folder", sep = "\n", filename = "~/.referee")
```

Obviously you will want to edit the path specification.  If you are operating on `charlie` it will be `/mnt/storage/data/edna/packages/referee`.

## Workflow scripts

  + `setup`  `source("setup.R")` this file first in all your workflow scripts (or interactive sessions). It loads the packages and sources ancillary functions. 
  
  + `restez_fetch_and_build_db` downloads and builds databasii sequentially 
  
  + `restez_build_db` builds databasii sequentially (for previously fetched databasii).  Use this in cases where Ben used the wrong `max_length` argument value to `restez::db_create()` the first time.
  
  + `idorgs` mines the genbank databasii (plant, vertebrate, invertebrate, mammalian and rodents) for all accession ids and organism names.  Results are saved in raw (long) and compacted form (wide).
  
  + `idorgs_reducer` accepts the (compacted) outout of  `idorgs` and a user specified `species` listing.  All `species` are assigned to an 'other' group to start with.  Then we iteratively attempt to match the user species to those in each of the `idorgs` (plant, vertebrate, invertebrate, mammalian and rodents).  We match with `base::match()` which uses byte matching which is very close to extact matching.  Where matches are detected the input species is assigned to that group.  In this manner we keep reducing the size of the query set.  With the remainder of unmatched species we try approximate matching using `base::agrep()` iteratively.
  
  + `taxizer` attempts to populate a complete taxonomy with IDs for a provided species list
  
  + `fastah` attempts to building a FASTA file of reference sequences for species with IDs.  We select for sequences length range 1-2000 base pairs.
  
  
### Running workflow scripts

Some of the workflows take a long time (days), so you'll want to be able to invoke the workflow and let it run in the background.  You have two options.

#### Use [screen](https://en.wikipedia.org/wiki/GNU_Screen)

`screen` is a utility available on linux and macos that allows you to start a processes in a shell, detach from the running process, and then reattach at some later time.  In that case you kick off a workflow script within your shell with the familiar call to`Rscript`.
 
```
$ Rscript /path/to/worflow/script.R /path/to/config/file.yaml
```

#### When available use a scheduler like [PBS](https://en.wikipedia.org/wiki/Portable_Batch_System)
  
Scheduling software is generally available on High Performance Computing (HPC) platforms.  We have created a shell script to manage the numerous configurations for each workflow.  The shell script makes sure the compute environment has the resources it needs to run.  Note that Bigelow's PBS configuration may be sloghtly different than your own.  Roughly speaking, you submit a request to enter the workflow into the queue, provide any named optionam arguments followed by the name of the shell script.  The shell script will call `Rscript` (as shown above) after it completes the session setup.

```
$ qsub -v cfgfile=/path/to/config/file.yaml /path/to/worflow/script.sh
```
  
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
  
[Accession ID](https://support.nlm.nih.gov/knowledgebase/article/KA-03434/en-us): more here specifically about [GenBank](https://support.nlm.nih.gov/knowledgebase/article/KA-03436/en-us)

Taxa ID:
  
[Restez](https://docs.ropensci.org/restez/) dastabasii: plant, vertebrate, invertebrate, mammalian and rodents
  