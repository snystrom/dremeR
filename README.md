
<!-- README.md is generated from README.Rmd. Please edit that file -->

# memes

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Codecov test
coverage](https://codecov.io/gh/snystrom/memes/branch/master/graph/badge.svg)](https://codecov.io/gh/snystrom/memes?branch=master)
![R-CMD-check-bioc](https://github.com/snystrom/memes/workflows/R-CMD-check-bioc/badge.svg)
![Bioconductor Build
Status](https://bioconductor.org/shields/build/devel/bioc/memes.svg)
![Bioconductor
Lifetime](https://bioconductor.org/shields/years-in-bioc/memes.svg)
<!-- badges: end -->

An R interface to the [MEME Suite](http://meme-suite.org/) family of
tools, which provides several utilities for performing motif analysis on
DNA, RNA, and protein sequences. memes works by detecting a local
install of the MEME suite, running the commands, then importing the
results directly into R.

## Installation

### Bioconductor

memes is currently available on the Bioconductor `devel` branch:

``` r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

# The following initializes usage of Bioc devel
BiocManager::install(version='devel')

BiocManager::install("memes")
```

### Development Version (Github)

You can install the development version of memes from
[GitHub](https://github.com/snystrom/memes) with:

``` r
if (!requireNamespace("remotes", quietly=TRUE))
  install.packages("remotes")
remotes::install_github("snystrom/memes")

# To temporarily bypass the R version 4.1 requirement, you can pull from the following branch:
remotes::install_github("snystrom/memes", ref = "no-r-4")
```

### Docker Container

``` shell
# Get development version from dockerhub
docker pull snystrom/memes_docker:devel
# the -v flag is used to mount an analysis directory, 
# it can be excluded for demo purposes
docker run -e PASSWORD=<password> -p 8787:8787 -v <path>/<to>/<project>:/mnt/<project> snystrom/memes_docker:devel
```

## Detecting the MEME Suite

memes relies on a local install of the [MEME
Suite](http://meme-suite.org/). For installation instructions for the
MEME suite, see the [MEME Suite Installation
Guide](http://meme-suite.org/doc/install.html?man_type=web).

memes needs to know the location of the `meme/bin/` directory on your
local machine. You can tell memes the location of your MEME suite
install in 4 ways. memes will always prefer the more specific definition
if it is a valid path. Here they are ranked from most- to
least-specific:

1.  Manually passing the install path to the `meme_path` argument of all
    memes functions
2.  Setting the path using `options(meme_bin = "/path/to/meme/bin/")`
    inside your R script
3.  Setting `MEME_BIN=/path/to/meme/bin/` in your `.Renviron` file
4.  memes will try the default MEME install location `~/meme/bin/`

If memes fails to detect your install at the specified location, it will
fall back to the next option.

To verify memes can detect your MEME install, use `check_meme_install()`
which uses the search herirarchy above to find a valid MEME install. It
will report whether any tools are missing, and print the path to MEME
that it sees. This can be useful for troubleshooting issues with your
install.

``` r
library(memes)

# Verify that memes detects your meme install
# (returns all green checks if so)
check_meme_install()
#> checking main install
#> ✓ /opt/meme/bin
#> checking util installs
#> ✓ /opt/meme/bin/dreme
#> ✓ /opt/meme/bin/ame
#> ✓ /opt/meme/bin/fimo
#> ✓ /opt/meme/bin/tomtom
#> ✓ /opt/meme/bin/meme
#> x /opt/meme/bin/streme
```

``` r
# You can manually input a path to meme_path
# If no meme/bin is detected, will return a red X
check_meme_install(meme_path = 'bad/path')
#> checking main install
#> x bad/path
```

## The Core Tools

| Function Name |              Use               | Sequence Input | Motif Input | Output                                                           |
|:-------------:|:------------------------------:|:--------------:|:-----------:|:-----------------------------------------------------------------|
| `runStreme()` | Motif Discovery (short motifs) |      Yes       |     No      | `universalmotif_df`                                              |
| `runDreme()`  | Motif Discovery (short motifs) |      Yes       |     No      | `universalmotif_df`                                              |
|  `runAme()`   |        Motif Enrichment        |      Yes       |     Yes     | data.frame (optional: `sequences` column)                        |
|  `runFimo()`  |         Motif Scanning         |      Yes       |     Yes     | GRanges of motif positions                                       |
| `runTomTom()` |        Motif Comparison        |       No       |     Yes     | `universalmotif_df` w/ `best_match_motif` and `tomtom` columns\* |
|  `runMeme()`  | Motif Discovery (long motifs)  |      Yes       |     No      | `universalmotif_df`                                              |

\* **Note:** if `runTomTom()` is run using a `universalmotif_df` the
results will be joined with the `universalmotif_df` results as extra
columns. This allows easy comparison of *de-novo* discovered motifs with
their matches.

**Sequence Inputs** can be any of:

1.  Path to a .fasta formatted file
2.  `Biostrings::XStringSet` (can be generated from GRanges using
    `get_sequence()` helper function)
3.  A named list of `Biostrings::XStringSet` objects (generated by
    `get_sequence()`)

**Motif Inputs** can be any of:

1.  A path to a .meme formatted file of motifs to scan against
2.  A `universalmotif` object, or list of `universalmotif` objects
3.  A `runDreme()` results object (this allows the results of
    `runDreme()` to pass directly to `runTomTom()`)
4.  A combination of all of the above passed as a `list()`
    (e.g. `list("path/to/database.meme", "dreme_results" = dreme_res)`)

**Output Types**:

`runDreme()`, `runStreme()`, `runMeme()` and `runTomTom()` return
`universalmotif_df` objects which are data.frames with special columns.
The `motif` column contains a `universalmotif` object, with 1 entry per
row. The remaining columns describe the properties of each returned
motif. The following column names are special in that their values are
used when running `update_motifs()` and `to_list()` to alter the
properties of the motifs stored in the `motif` column. Be careful about
changing these values as these changes will propagate to the `motif`
column when calling `update_motifs()` or `to_list()`.

-   name
-   altname
-   family
-   organism
-   strand
-   nsites
-   bkgsites
-   pval
-   qval
-   eval

memes is built around the [universalmotif
package](https://www.bioconductor.org/packages/release/bioc/html/universalmotif.html)
which provides a framework for manipulating motifs in R.
`universalmotif_df` objects can interconvert between data.frame and
`universalmotif` list format using the `to_df()` and `to_list()`
functions, respectively. This allows use of `memes` results with all
other Bioconductor motif packages, as `universalmotif` objects can
convert to any other motif type using `convert_motifs()`.

`runTomTom()` returns a special column: `tomtom` which is a `data.frame`
of all match data for each input motif. This can be expanded out using
`tidyr::unnest(tomtom_results, "tomtom")`, and renested with
`nest_tomtom()`. The `best_match_` prefixed columns returned by
`runTomTom()` indicate values for the motif which was the best match to
the input motif.

## Quick Examples

### Motif Discovery with DREME

``` r
suppressPackageStartupMessages(library(magrittr))
suppressPackageStartupMessages(library(GenomicRanges))

# Example transcription factor peaks as GRanges
data("example_peaks", package = "memes")

# Genome object
dm.genome <- BSgenome.Dmelanogaster.UCSC.dm6::BSgenome.Dmelanogaster.UCSC.dm6
```

The `get_sequence` function takes a `GRanges` or `GRangesList` as input
and returns the sequences as a `BioStrings::XStringSet`, or list of
`XStringSet` objects, respectively. `get_sequence` will name each fasta
entry by the genomic coordinates each sequence is from.

``` r
# Generate sequences from 200bp about the center of my peaks of interest
sequences <- example_peaks %>% 
  resize(200, "center") %>% 
  get_sequence(dm.genome)
```

`runDreme()` accepts XStringSet or a path to a fasta file as input. You
can use other sequences or shuffled input sequences as the control
dataset.

``` r
# runDreme accepts all arguments that the commandline version of dreme accepts
# here I set e = 50 to detect motifs in the limited example peak list
# In a real analysis, e should typically be < 1
dreme_results <- runDreme(sequences, control = "shuffle", e = 50)
```

memes is built around the
[universalmotif](https://www.bioconductor.org/packages/release/bioc/html/universalmotif.html)
package. The results are returned in `universalmotif_df` format, which
is an R data.frame that can seamlessly interconvert between data.frame
and `universalmotif` format using `to_list()` to convert to
`universalmotif` list format, and `to_df()` to convert back to
data.frame format. Using `to_list()` allows using `memes` results with
all `universalmotif` functions like so:

``` r
library(universalmotif)

dreme_results %>% 
  to_list() %>% 
  view_motifs()
```

<img src="man/figures/README-unnamed-chunk-8-1.png" style="display: block; margin: auto;" />

### Matching motifs using TOMTOM

Discovered motifs can be matched to known TF motifs using `runTomTom()`,
which can accept as input a path to a .meme formatted file, a
`universalmotif` list, or the results of `runDreme()`.

TomTom uses a database of known motifs which can be passed to the
`database` parameter as a path to a .meme format file, or a
`universalmotif` object.

Optionally, you can set the environment variable `MEME_DB` in
`.Renviron` to a file on disk, or the `meme_db` value in `options` to a
valid .meme format file and memes will use that file as the database.
memes will always prefer user input to the function call over a global
variable setting.

``` r
options(meme_db = system.file("extdata/flyFactorSurvey_cleaned.meme", package = "memes"))
m <- create_motif("CMATTACN", altname = "testMotif")
tomtom_results <- runTomTom(m)
```

``` r
tomtom_results
#>         motif  name   altname consensus alphabet strand icscore type
#> 1 <mot:motif> motif testMotif  CMATTACN      DNA     +-      13  PPM
#>                      bkg best_match_name best_match_altname
#> 1 0.25, 0.25, 0.25, 0.25      prd_FlyReg                prd
#>              best_db_name best_match_offset best_match_pval best_match_eval
#> 1 flyFactorSurvey_cleaned                 0        9.36e-05           0.052
#>   best_match_qval best_match_strand
#> 1          0.0353                 +
#>                                                       best_match_motif
#> 1 <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  tomtom
#> 1 prd_FlyReg, tup_SOLEXA_10, CG13424_Cell, CG11085_Cell, BH2_Cell, CG13424_SOLEXA_2, Tup_Cell, Tup_SOLEXA, Bsh_Cell, Exex_SOLEXA, Odsh_SOLEXA, Unc4_Cell, Ubx_FlyReg, Unc4_SOLEXA, E5_Cell, inv_SOLEXA_5, BH2_SOLEXA, Zen_SOLEXA, CG33980_SOLEXA_2_10, BH1_SOLEXA, CG33980_SOLEXA_2_0, Hgtx_Cell, NK7.1_Cell, Slou_Cell, CG13424_SOLEXA, Zen2_Cell, AbdA_SOLEXA, Antp_SOLEXA, Btn_Cell, Dfd_SOLEXA, Eve_SOLEXA, Ftz_Cell, Hmx_SOLEXA, Hmx_Cell, CG34031_Cell, zen2_SOLEXA_2, En_Cell, Pb_SOLEXA, Slou_SOLEXA, Unpg_Cell, inv_SOLEXA_2, ovo_FlyReg, lim_SOLEXA_2, C15_SOLEXA, Ems_Cell, Btn_SOLEXA, Unpg_SOLEXA, Pb_Cell, Bsh_SOLEXA, Scr_SOLEXA, Zen2_SOLEXA, CG34031_SOLEXA, Eve_Cell, Pph13_Cell, BH1_Cell, CG11085_SOLEXA, CG32532_Cell, en_FlyReg, Dll_SOLEXA, Dfd_Cell, Dr_SOLEXA, Ap_Cell, Ro_Cell, CG4136_SOLEXA, CG33980_SOLEXA, Hbn_SOLEXA, Lbl_Cell, Otp_Cell, Rx_Cell, CG32532_SOLEXA, NK7.1_SOLEXA, Dr_Cell, Odsh_Cell, Al_SOLEXA, Antp_Cell, Hgtx_SOLEXA, Ftz_SOLEXA, Lab_SOLEXA, Dfd_FlyReg, Ap_SOLEXA, Awh_SOLEXA, CG11294_SOLEXA, CG4136_Cell, E5_SOLEXA, Ro_SOLEXA, PhdP_SOLEXA, CG12361_SOLEXA_2, Ind_Cell, Scr_Cell, CG9876_Cell, CG18599_Cell, CG9876_SOLEXA, Otp_SOLEXA, Lbl_SOLEXA, Ubx_Cell, Ubx_SOLEXA, en_SOLEXA_2, Pph13_SOLEXA, Rx_SOLEXA, CG15696_SOLEXA, CG18599_SOLEXA, Ems_SOLEXA, Repo_Cell, Dll_Cell, C15_Cell, CG12361_SOLEXA, Abd-A_FlyReg, Repo_SOLEXA, Zen_Cell, Inv_Cell, En_SOLEXA, Lim3_Cell, Lim1_SOLEXA, CG15696_Cell, Crc_CG6272_SANGER_5, Lab_Cell, CG32105_SOLEXA, Bap_SOLEXA, CG9437_SANGER_5, AbdA_Cell, pho_FlyReg, CG33980_Cell, Cad_SOLEXA, CG4328_SOLEXA, CG4328_Cell, Gsc_Cell, vri_SANGER_5, AbdB_SOLEXA, Xrp1_CG6272_SANGER_5, Al_Cell, Exex_Cell, br-Z4_FlyReg, CG11294_Cell, Aef1_FlyReg, CG7745_SANGER_5, PhdP_Cell, Awh_Cell, prd, tup, lms, CG11085, B-H2, lms, tup, tup, bsh, exex, OdsH, unc-4, Ubx, unc-4, E5, inv, B-H2, zen, CG33980, B-H1, CG33980, HGTX, NK7.1, slou, lms, zen2, abd-A, Antp, btn, Dfd, eve, ftz, Hmx, Hmx, CG34031, zen2, en, pb, slou, unpg, inv, ovo, Lim1, C15, ems, btn, unpg, pb, bsh, Scr, zen2, CG34031, eve, Pph13, B-H1, CG11085, CG32532, en, Dll, Dfd, Dr, ap, ro, CG4136, CG33980, hbn, lbl, otp, Rx, CG32532, NK7.1, Dr, OdsH, al, Antp, HGTX, ftz, lab, Dfd, ap, Awh, CG11294, CG4136, E5, ro, PHDP, CG12361, ind, Scr, CG9876, CG18599, CG9876, otp, lbl, Ubx, Ubx, en, Pph13, Rx, CG15696, CG18599, ems, repo, Dll, C15, CG12361, abd-A, repo, zen, inv, en, Lim3, Lim1, CG15696, crc, lab, CG32105, bap, CG9437, abd-A, pho, CG33980, cad, CG4328, CG4328, Gsc, vri, Abd-B, Xrp1, al, exex, br, CG11294, Aef1, CG7745, PHDP, Awh, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, <S4 class 'universalmotif' [package "universalmotif"] with 20 slots>, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, flyFactorSurvey_cleaned, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, -3, 0, 4, 1, 0, 0, 0, 0, -2, 0, -2, 1, 0, -2, 1, 0, 2, -1, 0, 9.36e-05, 0.000129, 0.00013, 0.000194, 0.000246, 0.000247, 0.000319, 0.000364, 0.000427, 0.000435, 0.000473, 0.000473, 0.000556, 0.000643, 0.000694, 0.000728, 0.000748, 0.000748, 0.000785, 0.000828, 0.000849, 0.000868, 0.000868, 0.000868, 0.00102, 0.00113, 0.00116, 0.00116, 0.00116, 0.00116, 0.00116, 0.00116, 0.00118, 0.00126, 0.00134, 0.00141, 0.00144, 0.00145, 0.00145, 0.00154, 0.00161, 0.00165, 0.00173, 0.00177, 0.00177, 0.00179, 0.00179, 0.0019, 0.00191, 0.00191, 0.00191, 0.00203, 0.00203, 0.00203, 0.00212, 0.00214, 0.00219, 0.00232, 0.00242, 0.00247, 0.0026, 0.00264, 0.00264, 0.00268, 0.00282, 0.00282, 0.00282, 0.00282, 0.00282, 0.00286, 0.00286, 0.00296, 0.00305, 0.00316, 0.0032, 0.0032, 0.00326, 0.00326, 0.00341, 0.00348, 0.00348, 0.00348, 0.00348, 0.00348, 0.00348, 0.0035, 0.00359, 0.00359, 0.00359, 0.00364, 0.00372, 0.00372, 0.00372, 0.00387, 0.00387, 0.00412, 0.00415, 0.00424, 0.00424, 0.00439, 0.00452, 0.00452, 0.00467, 0.00483, 0.00497, 0.00497, 0.00528, 0.00549, 0.0059, 0.00597, 0.00624, 0.00635, 0.00709, 0.00761, 0.0079, 0.00856, 0.00859, 0.00912, 0.00935, 0.0097, 0.00974, 0.0101, 0.0109, 0.0116, 0.0123, 0.0123, 0.0127, 0.0138, 0.0138, 0.014, 0.014, 0.0147, 0.0148, 0.0155, 0.0165, 0.0166, 0.0177, 0.052, 0.0718, 0.0725, 0.108, 0.137, 0.137, 0.177, 0.202, 0.238, 0.242, 0.263, 0.263, 0.309, 0.357, 0.386, 0.405, 0.416, 0.416, 0.436, 0.46, 0.472, 0.483, 0.483, 0.483, 0.566, 0.629, 0.646, 0.646, 0.646, 0.646, 0.646, 0.646, 0.654, 0.702, 0.745, 0.785, 0.8, 0.808, 0.808, 0.858, 0.897, 0.92, 0.961, 0.985, 0.985, 0.993, 0.993, 1.05, 1.06, 1.06, 1.06, 1.13, 1.13, 1.13, 1.18, 1.19, 1.22, 1.29, 1.34, 1.38, 1.45, 1.47, 1.47, 1.49, 1.57, 1.57, 1.57, 1.57, 1.57, 1.59, 1.59, 1.65, 1.7, 1.76, 1.78, 1.78, 1.81, 1.81, 1.9, 1.94, 1.94, 1.94, 1.94, 1.94, 1.94, 1.95, 2, 2, 2, 2.02, 2.07, 2.07, 2.07, 2.15, 2.15, 2.29, 2.31, 2.36, 2.36, 2.44, 2.52, 2.52, 2.6, 2.68, 2.76, 2.76, 2.94, 3.05, 3.28, 3.32, 3.47, 3.53, 3.94, 4.23, 4.39, 4.76, 4.77, 5.07, 5.2, 5.39, 5.41, 5.61, 6.06, 6.42, 6.81, 6.81, 7.03, 7.66, 7.65, 7.78, 7.78, 8.15, 8.26, 8.59, 9.18, 9.2, 9.85, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353, 0.0368, 0.0369, 0.0369, 0.0369, 0.0369, 0.0369, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0372, 0.0379, 0.0379, 0.0381, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0396, 0.0404, 0.0404, 0.0424, 0.0424, 0.0424, 0.0424, 0.0435, 0.0439, 0.0439, 0.0449, 0.046, 0.0464, 0.0464, 0.0489, 0.0504, 0.0536, 0.0538, 0.0557, 0.0562, 0.0622, 0.0662, 0.0681, 0.0727, 0.0727, 0.0765, 0.0778, 0.0797, 0.0797, 0.0819, 0.0877, 0.0923, 0.0964, 0.0964, 0.0987, 0.106, 0.106, 0.106, 0.106, 0.11, 0.111, 0.114, 0.121, 0.121, 0.128, +, -, -, -, -, -, -, -, -, -, -, -, +, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, +, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, +, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, -, +, -, -, -, -, -, -, -, +, -, -, -, +, -, -, -, -, -, -, -, +, -, +, -, -, -, +, +, +, -, -
#> 
#> [Hidden empty columns: family, organism, nsites, bkgsites, pval, qval,
#>   eval.]
```

### Using runDreme results as TOMTOM input

`runTomTom()` will add its results as columns to a `runDreme()` results
data.frame.

``` r
full_results <- dreme_results %>% 
  runTomTom()
```

### Motif Enrichment using AME

AME is used to test for enrichment of known motifs in target sequences.
`runAme()` will use the `MEME_DB` entry in `.Renviron` or
`options(meme_db = "path/to/database.meme")` as the motif database.
Alternately, it will accept all valid inputs similar to `runTomTom()`.

``` r
# here I set the evalue_report_threshold = 30 to detect motifs in the limited example sequences
# In a real analysis, evalue_report_threshold should be carefully selected
ame_results <- runAme(sequences, control = "shuffle", evalue_report_threshold = 30)
ame_results
#> # A tibble: 2 x 17
#>    rank motif_db motif_id motif_alt_id consensus  pvalue adj.pvalue evalue tests
#>   <int> <chr>    <chr>    <chr>        <chr>       <dbl>      <dbl>  <dbl> <int>
#> 1     1 /usr/lo… Eip93F_… Eip93F       ACWSCCRA… 5.14e-4     0.0339   18.8    67
#> 2     2 /usr/lo… Cf2-PB_… Cf2          CSSHNKDT… 1.57e-3     0.0415   23.1    27
#> # … with 8 more variables: fasta_max <dbl>, pos <int>, neg <int>,
#> #   pwm_min <dbl>, tp <int>, tp_percent <dbl>, fp <int>, fp_percent <dbl>
```

## Visualizing Results

`view_tomtom_hits` allows comparing the input motifs to the top hits
from TomTom. Manual inspection of these matches is important, as
sometimes the top match is not always the correct assignment. Altering
`top_n` allows you to show additional matches in descending order of
their rank.

``` r
full_results %>% 
  view_tomtom_hits(top_n = 1)
#> $m01_AGAGC
```

<img src="man/figures/README-unnamed-chunk-13-1.png" style="display: block; margin: auto;" />

It can be useful to view the results from `runAme()` as a heatmap.
`plot_ame_heatmap()` can create complex visualizations for analysis of
enrichment between different region types (see vignettes for details).
Here is a simple example heatmap.

``` r
ame_results %>% 
  plot_ame_heatmap()
```

<img src="man/figures/README-unnamed-chunk-14-1.png" style="display: block; margin: auto;" />

### Scanning for motif occurances using FIMO

The FIMO tool is used to identify matches to known motifs. `runFimo`
will return these hits as a `GRanges` object containing the genomic
coordinates of the motif match.

``` r
# Query MotifDb for a motif
e93_motif <- MotifDb::query(MotifDb::MotifDb, "Eip93F") %>% 
  universalmotif::convert_motifs()
#> See system.file("LICENSE", package="MotifDb") for use restrictions.

# Scan for the E93 motif within given sequences
fimo_results <- runFimo(sequences, e93_motif, thresh = 1e-3)

# Visualize the sequences matching the E93 motif
plot_sequence_heatmap(fimo_results$matched_sequence)  
```

<img src="man/figures/README-unnamed-chunk-15-1.png" style="display: block; margin: auto;" />

## Importing Data from previous runs

memes also supports importing results generated using the MEME suite
outside of R (for example, running jobs on
[meme-suite.org](meme-suite.org), or running on the commandline). This
enables use of preexisting MEME suite results with downstream memes
functions.

| MEME Tool |    Function Name    | File Type  |
|:---------:|:-------------------:|:----------:|
|  Streme   | `importStremeXML()` | streme.xml |
|   Dreme   | `importDremeXML()`  | dreme.xml  |
|  TomTom   | `importTomTomXML()` | tomtom.xml |
|    AME    |    `importAme()`    | ame.tsv\*  |
|   FIMO    |   `importFimo()`    |  fimo.tsv  |
|   Meme    |   `importMeme()`    |  meme.txt  |

\* `importAME()` can also use the “sequences.tsv” output when AME used
`method = "fisher"`, this is optional.

# FAQs

### How do I use memes/MEME on Windows?

The MEME Suite does not currently support Windows, although it can be
installed under [Cygwin](https://www.cygwin.com/) or the [Windows Linux
Subsytem](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
(WSL). Please note that if MEME is installed on Cygwin or WSL, you must
also run R inside Cygwin or WSL to use memes.

An alternative solution is to use
[Docker](https://www.docker.com/get-started) to run a virtual
environment with the MEME Suite installed. We provide a [memes docker
container](https://github.com/snystrom/memes_docker)  
that ships with the MEME Suite, R studio, and all `memes` dependencies
pre-installed.

# Citation

memes is a wrapper for a select few tools from the MEME Suite, which
were developed by another group. In addition to citing memes, please
cite the MEME Suite tools corresponding to the tools you use.

If you use `runDreme()` in your analysis, please cite:

Timothy L. Bailey, “DREME: Motif discovery in transcription factor
ChIP-seq data”, Bioinformatics, 27(12):1653-1659, 2011. [full
text](https://academic.oup.com/bioinformatics/article/27/12/1653/257754)

If you use `runTomTom()` in your analysis, please cite:

Shobhit Gupta, JA Stamatoyannopolous, Timothy Bailey and William
Stafford Noble, “Quantifying similarity between motifs”, Genome Biology,
8(2):R24, 2007. [full text](http://genomebiology.com/2007/8/2/R24)

If you use `runAme()` in your analysis, please cite:

Robert McLeay and Timothy L. Bailey, “Motif Enrichment Analysis: A
unified framework and method evaluation”, BMC Bioinformatics, 11:165,
2010, <doi:10.1186/1471-2105-11-165>. [full
text](http://www.biomedcentral.com/1471-2105/11/165)

If you use `runFimo()` in your analysis, please cite:

Charles E. Grant, Timothy L. Bailey, and William Stafford Noble, “FIMO:
Scanning for occurrences of a given motif”, Bioinformatics,
27(7):1017-1018, 2011. [full
text](http://bioinformatics.oxfordjournals.org/content/early/2011/02/16/bioinformatics.btr064.full)

## Licensing Restrictions

The MEME Suite is free for non-profit use, but for-profit users should
purchase a license. See the [MEME Suite Copyright
Page](http://meme-suite.org/doc/copyright.html) for details.
