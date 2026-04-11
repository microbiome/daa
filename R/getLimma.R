#' @title Fit limma model
#'
#' @description
#' Fits a limma model using wide-format data and sample metadata.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable and the RHS specifies variables from \code{colData(tse)},
#'   e.g., \code{counts ~ Group}.
#' @param ... Additional arguments (reserved for future use).
#'
#' @return A fitted limma model object (result of \code{limma::eBayes}).
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' fit <- getLimma(tse, counts ~ Geographical_location)
#'
#' @export
getLimma <- function(tse, formula, ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .calculate_limma(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]]
    )
    return(res)
}

#' @keywords internal
#' @noRd
.calculate_limma <- function(formula, mat, metadata) {
    rhs_formula <- .get_rhs_formula(formula)
    design_mat <- stats::model.matrix(rhs_formula, data = metadata)

    fit <- limma::lmFit(mat, design_mat)
    fit <- limma::eBayes(fit)
    return(fit)
}
