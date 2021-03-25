# memes 0.1.0

* Removed `as_universalmotif_df()`, `as_universalmotif()`, and `update_motifs()`.
  * These functions are replaced by `universalmotif::to_df()`, `universalmotif::to_list()`, and `universalmotif::update_motifs()`
* `runDreme` and `runTomTom` results are now returned in `universalmotif_df` format (behaves just like a data.frame)
  * The `motif` column of `universalmotif_df` objects can no longer be called directly in `universalmotif` operations like `view_motifs(df$motif)`. Use `to_list()` for this behavior instead.
* `ame_plot_heatmap` ranking issue is resolved
* Added `remove_duplicate_motifs` and `has_duplicate_motifs` for detecting and removing duplicated matrices in a universalmotif object or data.frame
* Overhauled the Tidying Motifs vignette for more extensive EDA and a demo of deduplication