#' @title Fit linear model per feature
#'
#' @description
#' Fits a linear model per feature using wide-format data and sample metadata.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable and the RHS specifies variables from \code{colData(tse)},
#'   e.g., \code{rclr ~ Group}.
#' @param p_adjust_method \code{Character scalar} or \code{NULL}. Method passed
#'   to \code{p.adjust} for multiple testing correction. If \code{NULL}, no
#'   adjusted p-values are added. (Default: \code{"BH"})
#' @param ... Additional arguments (reserved for future use).
#'
#' @return A \code{data.frame} with per-feature model coefficients, p-values,
#'   and optionally adjusted p-values in column \code{q_value}.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' tse <- mia::transformAssay(tse, method = "rclr")
#' res <- getLm(tse, rclr ~ Geographical_location)
#'
#' @importFrom broom tidy
#' @importFrom stats lm
#' @export
getLm <- function(tse, formula, p_adjust_method = "BH", ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .train_model_per_feature(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]],
        FUN = .run_lm,
        p_adjust_method = p_adjust_method
    )
    return(res)
}

#' @keywords internal
#' @noRd
.run_lm <- function(abundance, metadata, formula) {
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    fit <- lm(abundance ~ ., data = mm)
    res <- tidy(fit)

    res <- res[res$term != "(Intercept)", c("term", "estimate", "p.value"),
        drop = FALSE
    ]
    colnames(res) <- c("variable", "estimate", "p_value")
    rownames(res) <- NULL
    return(res)
}
