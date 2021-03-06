library(memes)
library(GenomicRanges)
library(magrittr)

peaks <- system.file("extdata/peaks/e93_chr3.csv", package = "memes") %>%
  readr::read_csv() %>%
  GRanges

# These data use the dm3 reference genome
dm.genome <- BSgenome.Dmelanogaster.UCSC.dm3::BSgenome.Dmelanogaster.UCSC.dm3

# compute summits using the summit_position column
summits <- peaks %>%
  plyranges::anchor_start() %>%
  plyranges::mutate(width = 1) %>%
  plyranges::shift_right(mcols(.)$summit_position)

# Get sequences in a 100bp window around the peak summit
summit_flank <- summits %>%
  plyranges::anchor_center() %>%
  plyranges::mutate(width = 100)

# split by response to E93 binding
by_binding <- summit_flank %>%
  split(mcols(.)$peak_binding_description) %>%
  get_sequence(dm.genome)

example_dreme_by_binding <- runDreme(by_binding, "shuffle")

usethis::use_data(example_dreme_by_binding)
