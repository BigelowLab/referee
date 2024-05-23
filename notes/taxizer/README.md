Taxonomy
================

This doesn’t advance us into new territory, but tries to make one of the
early steps more modular by harvesting the full taxonomy (well, as much
as we can) early in the process.

Below we read in the result file, drop the IDs, and show a glimpse. Note
that the original listing from Erin was filtered to remove duplicates
(just shy of 300 dropped) and the binomial names were “sentence cased”
like `Genus species` before the search.

The search, using
[taxizedb](https://github.com/BigelowLab/mednaTaxaRef/blob/8391d8f31cdea70807a291c89782dc5ee5b11572/egrey/taxizer.R#L45),
worked best by breaking the list into
[chunks](https://github.com/BigelowLab/mednaTaxaRef/blob/8391d8f31cdea70807a291c89782dc5ee5b11572/egrey/input/taxizer.000.yaml#L12)
with a short doze between requests. It takes a few minutes to run.

``` r
path="/mnt/storage/data/edna/mednaTaxaRef/egrey/data/taxa"
x = readr::read_csv(file.path(path,"source_binomial-taxa.csv.gz"), col_type = "c") |>
  dplyr::select(-dplyr::ends_with("_id")) |>
  glimpse()
```

    ## Rows: 27,589
    ## Columns: 9
    ## $ tax_query    <chr> "Abagrotis alternata", "Abagrotis brunneipennis", "Abbott…
    ## $ superkingdom <chr> "Eukaryota", "Eukaryota", NA, "Eukaryota", "Eukaryota", "…
    ## $ kingdom      <chr> "Metazoa", "Metazoa", NA, "Viridiplantae", "Viridiplantae…
    ## $ phylum       <chr> "Arthropoda", "Arthropoda", NA, "Streptophyta", "Streptop…
    ## $ class        <chr> "Insecta", "Insecta", NA, "Magnoliopsida", "Pinopsida", "…
    ## $ order        <chr> "Lepidoptera", "Lepidoptera", NA, "Malvales", "Pinales", …
    ## $ family       <chr> "Noctuidae", "Noctuidae", NA, "Malvaceae", "Pinaceae", "P…
    ## $ genus        <chr> "Abagrotis", "Abagrotis", NA, "Abelmoschus", "Abies", "Ab…
    ## $ species      <chr> "Abagrotis alternata", "Abagrotis brunneipennis", NA, "Ab…

For each rank there is a companion column, `*_id`, but I dropped those
just for demonstration here.

So, which are completely identified and which are partially identified?
We make a flag (a letter) for each rank, and compose a code from the
flags we a missing rank is replaced with a “-” placeholder. So, a
complete identification has a codded flag like this `Skpcofgs`, but it
phylum is missing then it would look like this `Sk-cofgs`.
**S**uperkingdom was capitalized to allow for **s**pecies

``` r
flags = c("S", "k", "p", "c", "o", "f", "g", "s")
na = "-"
flag = apply(dplyr::select(x, -1) |> as.matrix(), 1,
                                function(r){
                                  ix = is.na(r)
                                  flags[ix] <- na
                                  paste(flags, collapse = "")
                                })
x = dplyr::mutate(x, flag = flag) |>
  dplyr::glimpse()
```

    ## Rows: 27,589
    ## Columns: 10
    ## $ tax_query    <chr> "Abagrotis alternata", "Abagrotis brunneipennis", "Abbott…
    ## $ superkingdom <chr> "Eukaryota", "Eukaryota", NA, "Eukaryota", "Eukaryota", "…
    ## $ kingdom      <chr> "Metazoa", "Metazoa", NA, "Viridiplantae", "Viridiplantae…
    ## $ phylum       <chr> "Arthropoda", "Arthropoda", NA, "Streptophyta", "Streptop…
    ## $ class        <chr> "Insecta", "Insecta", NA, "Magnoliopsida", "Pinopsida", "…
    ## $ order        <chr> "Lepidoptera", "Lepidoptera", NA, "Malvales", "Pinales", …
    ## $ family       <chr> "Noctuidae", "Noctuidae", NA, "Malvaceae", "Pinaceae", "P…
    ## $ genus        <chr> "Abagrotis", "Abagrotis", NA, "Abelmoschus", "Abies", "Ab…
    ## $ species      <chr> "Abagrotis alternata", "Abagrotis brunneipennis", NA, "Ab…
    ## $ flag         <chr> "Skpcofgs", "Skpcofgs", "--------", "Skpcofgs", "Skpcofgs…

We’ll use the `flag` to our advantage with a simple tally.

``` r
N = nrow(x)
tally = dplyr::count(x, flag) |>
  dplyr::mutate(proportion = round(n/N * 100,3))
print(tally, n = nrow(tally))
```

    ## # A tibble: 22 × 3
    ##    flag         n proportion
    ##    <chr>    <int>      <dbl>
    ##  1 --------  8920     32.3  
    ##  2 S----fgs     1      0.004
    ##  3 S---o-gs     1      0.004
    ##  4 S--c--gs     1      0.004
    ##  5 S--cofgs   163      0.591
    ##  6 S-p----s     2      0.007
    ##  7 S-p---gs     2      0.007
    ##  8 S-p-o-gs     1      0.004
    ##  9 S-p-ofgs    44      0.159
    ## 10 S-pc--gs     3      0.011
    ## 11 S-pc-fgs    17      0.062
    ## 12 S-pco-gs    10      0.036
    ## 13 S-pcof-s     1      0.004
    ## 14 S-pcofgs  1280      4.64 
    ## 15 Skp---gs     8      0.029
    ## 16 Skp--fgs     3      0.011
    ## 17 Skp-ofgs    34      0.123
    ## 18 Skpc--gs    15      0.054
    ## 19 Skpc-fgs   138      0.5  
    ## 20 Skpco-gs    47      0.17 
    ## 21 Skpcof-s     1      0.004
    ## 22 Skpcofgs 16897     61.2
