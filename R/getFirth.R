#' @title Fit Firth logistic regression per feature
#'
#' @description
#' Fits Firth logistic regression per feature using wide-format data.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable (must be binary/presence-absence) and the RHS specifies variables
#'   from \code{colData(tse)}, e.g., \code{pa ~ Group + Age}.
#' @param p_adjust_method \code{Character scalar} or \code{NULL}. Method passed
#'   to \code{p.adjust} for multiple testing correction. If \code{NULL}, no
#'   adjusted p-values are added. (Default: \code{"BH"})
#' @param ... Additional arguments (reserved for future use).
#'
#' @return A \code{data.frame} with per-feature model coefficients, p-values,
#'   and optionally adjusted p-values in column \code{q_value}.
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
#' @importFrom logistf logistf logistf.control
#' @export
getFirth <- function(tse, formula, p_adjust_method = "BH", ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .train_model_per_feature(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]],
        FUN = .run_firth,
        p_adjust_method = p_adjust_method
    )
    return(res)
}

#' @keywords internal
#' @noRd
.run_firth <- function(abundance, metadata, formula) {
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    fit <- logistf(
        abundance ~ .,
        data = mm,
        control = logistf.control(maxit = 1000)
    )

    res <- data.frame(
        estimate = fit$coefficients,
        p_value = fit$prob
    )

    res <- res[!rownames(res) %in% c("(Intercept)"), , drop = FALSE]
    res[["variable"]] <- rownames(res)
    rownames(res) <- NULL
    return(res)
}
