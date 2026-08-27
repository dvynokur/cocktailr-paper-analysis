# cocktailr-paper-analysis

This repository contains analysis code and supplementary-material generation scripts for the manuscript:

**Vegetation classification based on diagnostic species groups: an end-to-end Cocktail workflow for large databases**

The repository is separate from the main `cocktailr` R package repository:  
https://github.com/dvynokur/cocktailr

## Contents

```text
appendix/   Appendix S1 source file
scripts/    R scripts used for setup, data loading, benchmarking and appendix rendering
outputs/    Generated figures, tables and supplementary files
```

## Data availability

The small illustrative example uses the `vegan::dune` dataset, available in the `vegan` R package.

The Southern European vegetation dataset used for the large-scale example was derived from the European Vegetation Archive (EVA) and is subject to EVA data-use restrictions. Therefore, plot-level data are not redistributed in this repository. Access to EVA data can be requested through EVA according to its data-access policy.

## Appendix S1

Appendix S1 can be rendered with:

```r
source("scripts/generate_appendix.R")
```

The rendered PDF is written to:

```text
outputs/appendix/
```

## Software

The analyses were run using `cocktailr` version 0.1.1, corresponding to GitHub release `v0.1.1`:

```r
remotes::install_github("dvynokur/cocktailr@v0.1.1")
```
