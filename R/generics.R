#' @noRd
sequence_input <- function(x) UseMethod("sequence_input")

#' @noRd
motif_input <- function(x, ...) UseMethod("motif_input")

#' Get sequence from GRanges
#'
#' A light wrapper around Biostrings::getSeq to return named DNAStringSets, from
#' input genomic coordinates.
#'
#' @param regions GRanges, or GRangesList object. Will also accept a data.frame
#'   as long as it can be coerced to a GRanges object, or a string in the
#'   format: "chr:start-end" (NOTE: use 1-based closed
#'   intervals, not BED format 0-based half-open intervals).
#' @param genome object of any valid type in `showMethods(Biostrings::getSeq)`.
#'   Commonly a BSgenome object, or fasta file. Used to look up sequences in regions.
#' @param score_column optional name of column (in mcols() of `regions`)
#'   containing a fasta score that is added to the fasta header of each entry.
#'   Used when using [runAme()] in partitioning mode. (default: `NULL`)
#' @param ... additional arguments passed to Biostrings::getSeq.
#'
#' @return `Biostrings::DNAStringSet` object with names corresponding to genomic
#'   coordinates. If input is a list object, output will be a
#'   `Biostrings::BStringSetList` with list names corresponding to input list
#'   names.
#'
#' @export
#' @importFrom GenomicRanges mcols `mcols<-`
#' @examples
#' # using character string as coordinates
#' # using BSgenome object for genome
#' drosophila.genome <- BSgenome.Dmelanogaster.UCSC.dm6::BSgenome.Dmelanogaster.UCSC.dm6
#' get_sequence("chr2L:100-200", drosophila.genome)
#'
#' # using GRanges object for coordinates
#' data(example_peaks, package = "memes")
#' get_sequence(example_peaks, drosophila.genome)
get_sequence <- function(regions, genome, score_column, ...) UseMethod("get_sequence")

#' Denovo motif discovery of target regions using DREME
#'
#' DREME discovers short, ungapped, *de-novo* motifs that are relatively
#' enriched relative to a control set of sequences. DREME can be run to discover
#' motifs relative to a shuffled set of input sequences, or against a separately
#' provided set of "control" sequences.
#'
#' Properly setting the `control` parameter is key to discovering biologically
#' relevant motifs. Often, using `control = "shuffle"` will produce a suboptimal
#' set of motifs; however, some discriminative analysis designs don't have
#' proper "control" regions other than to shuffle.
#' 
#' As of MEME version 5.2.0, DREME is deprecated. Consider [runStreme()] instead.
#'
#' @param input regions to scan for motifs. Can be any of:
#'   - path to fasta file
#'   - DNAStringSet object (can be generated from GRanges using `get_sequence()`)
#'   - List of DNAStringSet objects (generated from `get_sequence()`)
#'   - *NOTE:* if using StringSet inputs, each entry must be named (set with `names()`).
#'   - *NOTE:* If you want to retain the raw dreme output files, you must use a
#'   path to fasta file as input, or specify an "outdir"
#' @param control regions to use as background for motif search. Can be any of:
#'   - path to fasta file
#'   - DNAStringSet object (can be generated from GRanges using get_sequence)
#'   - A Biostrings::BStringSetList (generated using `get_sequence`), in which
#'   case all sequences in the list will be combined as the control set.
#'   - if `input` is a list of DNAStringSet objects, a character vector of names
#'   in `input` will use those sequences as background. runDreme will not scan
#'   those regions as input.
#'   - "shuffle" to use dreme's built-in dinucleotide shuffle feature (NOTE: if
#'   `input` is a list object with an entry named "shuffle", the list entry will
#'   be used instead).
#'   Optionally can also pass `seed = <any number>` to `...` to use as the random
#'   seed during shuffling. If no seed is passed, dreme will use 1 as the random
#'   seed, so results will be reproducible if rerunning. **NOTE:** beware
#'   system-specific differences. As of v5, dreme will compile using the default
#'   python installation on a system (either python2.7 or python3). The random
#'   number generator changed between python2.7 and python3, so results will not
#'   be reproducible between systems using python2.7 vs 3.
#' @param outdir path to output directory of dreme files, or "auto" to autogenerate path. Default: location of
#'   input fasta in dir named "\<input\>_vs_\<control\>". If input is
#'   DNAstringset, will be temporary path. This means that if you want to save
#'   the raw output files, you must use fasta files as input or use an
#'   informative (and unique) outdir name. memes will **not check** if it
#'   overwrites files in a directory. Directories will be recursively created if needed.
#' @param meme_path optional, path to "meme/bin/" on your local machine.
#'   runDreme will search 3 places in order for meme if this flag is unset:
#'    1. the option "meme_bin" (set with options(meme_bin = "path/to/meme/bin"))
#'    2. the environment variable "MEME_PATH" (set in .Renviron)
#'    3. "~/meme/bin/" as the default location
#'    - If the user sets meme_path in the function call, this value will always be used
#'
#' @param silent whether to suppress printing dreme stdout as a message when
#'   finishing with no errors. Can be useful for troubleshooting in situations
#'   where no motifs are discovered, but command completes successfully.
#'   (default: TRUE)
#'
#' @param ... dreme flags can be passed as R function arguments to use
#'   non-default behavior. For a full list of valid arguments, run your local
#'   install of dreme -h, or visit the dreme documentation
#'   [website](http://meme-suite.org/doc/dreme.html). See list below for aliases
#'   of common flags. To set flags with no values (ex. `-dna`), pass the
#'   argument as a boolean value (ex. `dna = TRUE`).
#'
#' @details
#' In addition to allowing any valid flag of dreme to be passed to `...`, we
#' provide a few user-friendly aliases for common flags which are more readable (see list below).
#' For example, e = 1 will use a max evalue cutoff of 1. This is equivalent to
#' setting evalue = 1. For additional details about each DREME flag, see the
#' [DREME Manual Webpage](http://meme-suite.org/doc/dreme.html).
#'
#' List of values which can be passed to `...`:
#' **NOTE:** values must be referred to using their name in the "memes alias"
#'   column, not the "DREME Flag" column.
#'
#' | memes alias  | DREME Flag | description                                | default |
#' |:------------:|:----------:|:-------------------------------------------|:-------:|
#' | nmotifs      | m          | max number of motifs to discover           | NULL    |
#' | sec          | t          | max number of seconds to run               | NULL    |
#' | evalue       | e          | max E-value cutoff                         | 0.05    |
#' | seed         | s          | random seed if using "shuffle" as control  | 1       |
#' | ngen         | g          | nuber of REs to generalize                 | 100     |
#' | mink         | mink       | minimum motif width to search              | 3       |
#' | maxk         | maxk       | maximum motif width to search              | 7       |
#' | k            | k          | set mink and maxk to this value            | NULL    |
#' | norc         | norc       | search only the input strand for sequences | FALSE   |
#' | dna          | dna        | use DNA alphabet                           | TRUE    |
#' | rna          | rna        | use RNA alphabet                           | FALSE   |
#' | protein      | protein    | use protein alphabet (NOT RECCOMENDED)     | FALSE   |
#'
#'
#' @return `universalmotif_df` with statistics for each discovered motif. The `motif`
#'   column contains a universalmotif object representation in PCM format of
#'   each DREME motif. If no motifs are discovered, returns NULL. The column
#'   values are as follows:
#'   - rank = ranked order of discovered motif
#'   - name = primary name of motif
#'   - altname = alternative name of motif
#'   - seq = consensus sequence of the motif
#'   - length = length of discovered motif
#'   - nsites = number of times the motif is found in input sequences
#'   - positive_hits = number of sequences in input containing at least 1 of the motif
#'   - negative_hits = number of sequences in control containing at least 1 of the motif
#'   - pval = p-value
#'   - eval = E-value
#'   - unerased_eval = Unerased E-Value
#'   - positive_total = number of sequences in input
#'   - negative_total = number of sequences in control
#'   - pos_frac = fraction of positive sequences with a hit
#'   - neg_frac = fraction of negative sequences with a hit
#'   - motif = a universalmotif object of the discovered motif
#'
#' @details # Citation
#' If you use `runDreme()` in your analysis, please cite:
#'
#' Timothy L. Bailey, "DREME: Motif discovery in transcription factor ChIP-seq
#' data", Bioinformatics, 27(12):1653-1659, 2011.
#' [full text](https://academic.oup.com/bioinformatics/article/27/12/1653/257754)
#'
#' @details ## Licensing
#' The MEME Suite is free for non-profit use, but for-profit users should purchase a
#' license. See the [MEME Suite Copyright Page](http://meme-suite.org/doc/copyright.html) for details.
#'
#' @importFrom magrittr %>%
#' @export
#' @md
#' @examples
#' if (meme_is_installed()) {
#' # Create random named sequences as input for example
#' seqs <- universalmotif::create_sequences(rng.seed = 123)
#' names(seqs) <- seq_along(seqs)
#' 
#' # Runs dreme with default settings, shuffles input as background
#' runDreme(seqs, "shuffle")
#'
#' # Runs searching for max 2 motifs, e-value cutoff = 0.1, explicitly using the DNA alphabet
#' runDreme(seqs, "shuffle", nmotifs = 2, e = 0.1, dna = TRUE)
#' }
runDreme <- function(input, control, outdir = "auto", meme_path = NULL, silent = TRUE, ...) {
  UseMethod("runDreme")
}

#' Motif enrichment using AME
#'
#' AME identifies known motifs (provided by the user) that are enriched in your input sequences.
#'
#' AME can be run using several modes:
#'  1. Discriminative mode: to discover motifs enriched relative to shuffled
#'  input, or a set of provided control sequences
#'  2. Partitioning mode: in which AME uses some biological signal to identify
#'  the association between the signal and motif presence.
#'
#' To read more about how AME works, see the [AME Tutorial](http://meme-suite.org/doc/ame-tutorial.html)
#'
#' @param input path to fasta, or DNAstringset (optional: DNAStringSet object
#'   names contain fasta score, required for partitioning mode)
#' @param control default: "shuffle", or set to
#'   DNAstringset or path to fasta file to use those sequences in discriminative
#'   mode. If `input` is a list of DNAStringSet objects, and `control` is set to
#'   a character vector of names in `input`, those regions will be used as
#'   background in discriminitive mode and AME will skip running on any
#'   `control` entries (NOTE: if `input` contains an entry named "shuffle" and
#'   control is set to "shuffle", it will use the `input` entry, not the AME
#'   shuffle algorithm). If `control` is a Biostrings::BStringSetList (generated
#'   using `get_sequence`), all sequences in the list will be combined as the
#'   control set. Set to `NA` for partitioning based on input fasta score (see
#'   `get_sequence()` for assigning fasta score). If input sequences are not
#'   assigned fasta scores but AME is run in partitioning mode, the sequence
#'   order will be used as the score.
#' @param outdir Path to output directory location to save data files. If set to "auto",
#'   will use location of input files if passing file paths, otherwise will
#'   write to a temporary directory. default: "auto"
#' @param method default: fisher (allowed values: fisher, ranksum, pearson, spearman, 3dmhg, 4dmhg)
#' @param database path to .meme format file, universalmotif list object, dreme
#'   results data.frame, or list() of multiple of these. If objects are assigned names in the list,
#'   that name will be used as the database id in the output. It is highly
#'   recommended you set a name if not using a file path so the database name
#'   will be informative, otherwise the position in the list will be used as the
#'   database id. For example, if the input is: list("motifs.meme",
#'   list_of_motifs), the database id's will be: "motifs.meme" and "2". If the
#'   input is list("motifs.meme", "customMotifs" = list_of_motifs), the database
#'   id's will be "motifs.meme" and "customMotifs".
#' @param meme_path path to "meme/bin/" (default: `NULL`). Will use default
#'   search behavior as described in `check_meme_install()` if unset.
#' @param sequences `logical(1)` add results from `sequences.tsv` to `sequences`
#'   list column to returned data.frame. Valid only if method = "fisher". See
#'   [AME outputs](http://alternate.meme-suite.org/doc/ame-output-format.html)
#'   webpage for more information (Default: FALSE).
#' @param silent whether to suppress stdout (default: TRUE), useful for debugging.
#' @param ... additional arguments passed to AME (see AME Flag table below)
#'
#' @details Additional AME arguments
#'
#' memes allows passing any valid flag to it's target programs via `...`. For
#' additional details for all valid AME arguments, see the [AME
#' Manual](http://meme-suite.org/doc/ame.html) webpage. For convenience, a table
#' of valid parameters, and brief descriptions of their function are provided
#' below:
#'
#'
#' | AME Flag                | allowed values | default | description                |
#' |:-----------------------:|:--------------:|:-------:|:---------------------------|
#' | kmer                    | `integer(1)`   | 2       | kmer frequency to preserve when shuffling control sequences |
#' | seed                    | `integer(1)`   | 1       | seed for random number generator when shuffling control sequences |
#' | scoring                 | "avg", "max", "sum", "totalhits" | "avg" | Method for scoring a sequence for matches to a PWM (avg, max, sum, totalhits) |
#' | hit_lo_fraction         | `numeric(1)`   | 0.25    | fraction of hit log odds score to exceed to be considered a "hit" |
#' | evalue_report_threshold | `numeric(1)`   | 10      | E-value threshold for reporting a motif as significantly enriched |
#' | fasta_threshold         | `numeric(1)`   | 0.001   | AME will classify sequences with FASTA scores below this value as positives. Only valid when `method = "fisher", poslist = "pwm", control = NA, fix_partition = NULL`. |
#' | fix_partition           | `numeric(1)`   | `NULL`  |AME evaluates only the partition of the first N sequences. Only works when `control = NA` and `poslist = "fasta"` |
#' | poslist                 | "pwm", "fasta" | "fasta" | When using paritioning mode (`control = NA`), test thresholds on either PWM or Fasta score |
#' | log_fscores             | `logical(1)`   | FALSE   | Convert FASTA scores into log-space (only used when `method = "pearson"`) |
#' | log_pwmscores           | `logical(1)`   | FALSE   | Convert PWM scores into log-space (only used for `method = "pearson"` or `method = "spearman`) |
#' | lingreg_switchxy        | `logical(1)`   | FALSE   | Make the x-points FASTA scores and y-points PWM scores (only used for `method = "pearson"` or `method = "spearman`) |
#' | xalph                   | file path      | `NULL(1)`  | alphabet file to use if input motifs are in different alphabet than input sequences |
#' | bfile                   | "motif", "motif-file", "uniform", path to file | `NULL` | source of 0-order background model. If "motif" or "motif-file" 0-order letter frequencies in the first motif file are used. If "uniform" uses uniform letter frequencies. |
#' | motif_pseudo            | `numeric(1)`   | 0.1     | Addd this pseudocount when converting from frequency matrix to log-odds matrix |
#' | inc                     | `character(1)` | `NULL`  | use only motifs with names matching this regex |
#' | exc                     | `character(1)` | `NULL`  | exclude motifs with names matching this regex  |
#'
#' @return a data.frame of AME enrichment results. If run using a BStringsSetList
#'   input, returns a list of data.frames.
#'
#'
#' @details # Citation
#'
#' If you use `runAme()` in your analysis, please cite:
#'
#' Robert McLeay and Timothy L. Bailey, "Motif Enrichment Analysis: A unified
#' framework and method evaluation", BMC Bioinformatics, 11:165, 2010,
#' doi:10.1186/1471-2105-11-165. [full text](http://www.biomedcentral.com/1471-2105/11/165)
#'
#' @details ## Licensing
#' The MEME Suite is free for non-profit use, but for-profit users should purchase a
#' license. See the [MEME Suite Copyright Page](http://meme-suite.org/doc/copyright.html) for details.
#'
#'
#' @export
#' @rdname runAme
#'
#' @md
#'
#' @importFrom magrittr %>%
#' @importFrom magrittr %T>%
#'
#' @examples
#' if (meme_is_installed()) {
#' # Create random named sequences as input for example
#' seqs <- universalmotif::create_sequences(rng.seed = 123)
#' names(seqs) <- seq_along(seqs)
#' 
#' # An example path to a motif database file in .meme format
#' motif_file <- system.file("extdata", "flyFactorSurvey_cleaned.meme", package = "memes")
#' 
#' runAme(seqs, database = motif_file)
#'
#' # Dreme results dataset for example
#' dreme_xml <- system.file("extdata", "dreme.xml", package = "memes")
#' dreme_results <- importDremeXML(dreme_xml)
#'
#' # database can be set to multiple values like so: 
#' runAme(seqs, database = list(motif_file, "my_dreme_motifs" = dreme_results))
#' }
runAme <- function(input,
       control = "shuffle",
       outdir = "auto",
       method = "fisher",
       database = NULL,
       meme_path = NULL,
       sequences = FALSE, silent = TRUE, ...){
  UseMethod("runAme")
}
