#' Force best tomtom match by id
#'
#' Although TomTom assigns a best match, this is not always the most
#' biologically relevant match. In these cases, it is useful to "force" the best
#' match to another lower ranked, but still significant TomTom match. This
#' function allows users to select a new best match motif from the set of
#' lower-ranked matches in the `tomtom` list column. This function also reorders
#' the `tomtom` data.frame such that the forced match is the first row of the
#' `tomtom` entry.
#'
#' @seealso [update_best_match()]
#'
#' @param res results from runTomTom
#' @param matches named vector where name is the input motif name, and value is
#'   the match_name to use as the new best match
#'
#' @return `res` with new best_* columns and re-ranked tomtom data in the
#'   `tomtom` list column for the updated entries.
#' @export
#'
#' @examples
#' if (meme_is_installed()){
#' motif <- universalmotif::create_motif("CCRAAAW", name = "example_motif")
#' db <- system.file("extdata", "flyFactorSurvey_cleaned.meme", package = "memes")
#' res <- runTomTom(motif, database = db)
#' res$best_match_name
#' res2 <- force_best_match(res, c("example_motif" = "Eip93F_SANGER_10"))
#' res2$best_match_name
#' }
force_best_match <- function(res, matches){
  # WAIT: change example to use tomtom.xml import?
  if (!all(names(matches) %in% res$name)) {
    bad <- names(matches)[!names(matches) %in% res$name]
    stop(paste0("The following are invalid names: ", bad))
  }

  purrr::iwalk(matches, ~{

    if (!(.x %in% res[res$name == .y,]$tomtom[[1]]$match_name)) {
      stop(paste0(.x, " is not found within the tomtom hits for ", .y))
    }

    res[res$name == .y,]$tomtom[[1]] <<- res[res$name == .y,]$tomtom[[1]] %>%
      rank_tomtom_by_name(.x)
  })

  res %>%
    update_best_match
}

#' Update best match info by ranking of tomtom data
#'
#' This function updates the best_match columns based on the rankings on the
#' tomtom list data. By re-ordering the entries of a `tomtom` object, the
#' best_match columns can be updated to reflect the new rankings using
#' [update_best_match()], where the first row of the `tomtom` data.frame is
#' selected as the best match.
#'
#' @seealso [force_best_match()]
#'
#' @param res results from runTomTom
#'
#' @return `res` with updated best_* columns
#' @export
#'
#' @importFrom tidyr unnest
#'
#' @examples
#' data("example_dreme_tomtom")
#' # best match is "CG2052_SANGER_2.5"
#' example_dreme_tomtom$best_match_name[1]
#' # reorder the `tomtom` data.frame
#' example_dreme_tomtom$tomtom[[1]] <- dplyr::arrange(example_dreme_tomtom$tomtom[[1]],
#'                                                    dplyr::desc(match_eval))
#' # update_best_match will use the new order of rows, taking the top row as the new best match
#' new_res <- update_best_match(example_dreme_tomtom)
#' # best match is now altered:
#' new_res$best_match_name[1]
update_best_match <- function(res){
  # This initial drop step is required because S4 not allowed in parent
  # data.frame when nesting, and `best_match_motif` would propagate. (`motif`
  # already removed by nest_tomtom)
  res_nobest <- res %>%
    drop_best_match()

  new_tomtom <- res_nobest %>%
    tidyr::unnest("tomtom") %>%
    nest_tomtom_results_best_top_row()
}

#' Drop best match columns from tomtom results
#'
#' Convenience function for dropping all columns created by runTomTom prefixed
#' by "best_match_" and the "best_db_name" column. Keeps the "tomtom" data.frame
#' column. Can be useful if you want to unnest the `tomtom` data without
#' propagating these columns.
#'
#' @param res results of runTomTom
#'
#' @return `res` without the tomtom best_match_ columns
#' @export
#'
#' @examples
#' data("example_dreme_tomtom")
#' names(example_dreme_tomtom)
#' names(drop_best_match(example_dreme_tomtom))
drop_best_match <- function(res){
  res %>%
    dplyr::select(-dplyr::contains("best_match_"),
                  -dplyr::any_of("best_db_name"))

}

#' Nest TomTom results columns into a data.frame column named "tomtom"
#'
#' This is a convienience function for re-nesting the `tomtom` list column if
#' the user unnests it. Additionally, it will update the best_match information
#' based on the ranking of the resulting `tomtom` data.frame. This avoids having
#' out-of-date best_match information after manipulating the `tomtom` entries.
#'
#' **NOTE:** that the resulting columns may not be in the same order, so
#' operations like `identical()` before & after a nest/renest operation may fail
#' even though the column values are unchanged.
#'
#' @param data tomtom results data.frame after unnesting the `tomtom` column
#'
#' @return the input data.frame with the match_* columns nested into a column named `tomtom`
#' @export
#'
#' @importFrom magrittr %<>%
#' @importFrom tidyr nest
#' @examples
#' if (meme_is_installed()){
#' motif <- universalmotif::create_motif("CCRAAAW")
#' db <- system.file("extdata/flyFactorSurvey_cleaned.meme", package = "memes")
#' res <- runTomTom(motif, database = db)
#' data <- tidyr::unnest(res, "tomtom")
#' identical(nest_tomtom(data), res)
#' }
nest_tomtom <- function(data){
  # Save motifs
  motif <- data$motif
  names(motif) <- data$name
  motif <- unique(motif)

  match_motif <- data$match_motif

  # tidyr::nest doesn't work with S4 because vctrs doesn't support it
  df <- data %>%
    dplyr::select(-dplyr::any_of(c("motif", "match_motif", "best_match_motif"))) %>%
    tidyr::nest(data = c("match_name",
                "match_altname",
                "match_pval",
                "match_eval",
                "match_qval",
                "db_name")) %>%
    dplyr::rename("tomtom" = "data")

  # add back motifs
  df$motif <- motif
  # Add database motifs to tomtom
  i <- 1
  df$tomtom <- lapply(df$tomtom, function(x) {
    n <- nrow(x)
    j <- i + n - 1
    x$match_motif <- match_motif[i:j]
    i <<- j + 1
    return(x)
  })

  df %>%
    update_best_match()
}

#' Rank a tomtom results dataframe by match_name
#'
#' @param tomtom
#'
#' @param match_name
#'
#' @importFrom rlang !!
#' @importFrom magrittr %>%
#' @importFrom dplyr desc
#'
#' @noRd
rank_tomtom_by_name <- function(tomtom, match_name){

  tomtom %>%
    dplyr::arrange(desc(match_name %in% !!match_name))

}
