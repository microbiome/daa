#' @title Fit ordinal regression model per feature
#'
#' @description
#' Fits an ordinal regression model (ORM) per feature using wide-format data.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable and the RHS specifies variables from \code{colData(tse)},
#'   e.g., \code{counts ~ Group}.
#' @param ... Additional arguments (reserved for future use).
#'
#' @return A \code{data.frame} with per-feature model coefficients, p-values,
#'   and BH-adjusted q-values.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getOrm(tse, counts ~ Geographical_location)
#'
#' @export
getOrm <- function(tse, formula, ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .train_model_per_feature(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]],
        FUN = .run_orm
    )
    return(res)
}
