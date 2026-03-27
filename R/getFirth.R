#' @title Fit Firth logistic regression per feature
#'
#' @description
#' Fits Firth logistic regression per feature using wide-format data.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable (must be binary/presence-absence) and the RHS specifies variables
#'   from \code{colData(tse)}, e.g., \code{pa ~ Group + Age}.
#' @param ... Additional arguments (reserved for future use).
#'
#' @return A \code{data.frame} with per-feature model coefficients, p-values,
#'   and BH-adjusted q-values.
#'
#' @examples
#' \dontrun{
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' tse <- mia::transformAssay(tse, method = "pa")
#' res <- getFirth(tse, pa ~ Geographical_location)
#' }
#'
#' @export
getFirth <- function(tse, formula, ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .train_model_per_feature(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]],
        FUN = .run_firth
    )
    return(res)
}
