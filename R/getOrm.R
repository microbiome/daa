#' @title Fit ordinal regression model per feature
#'
#' @description
#' Fits an ordinal regression model (ORM) per feature using wide-format data.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the assay or colData
#'   variable and the RHS specifies variables from \code{colData(tse)},
#'   e.g., \code{counts ~ Group}.
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
#' res <- getOrm(tse, counts ~ Geographical_location)
#'
#' @importFrom rms orm
#' @importFrom stats pchisq
#' @export
getOrm <- function(tse, formula, p_adjust_method = "BH", ...) {
    data_list <- .get_wide_data(tse, formula)
    res <- .train_model_per_feature(
        formula = formula,
        mat = data_list[["matrix"]],
        metadata = data_list[["sample_metadata"]],
        FUN = .run_orm,
        p_adjust_method = p_adjust_method
    )
    return(res)
}

#' @keywords internal
#' @noRd
.run_orm <- function(abundance, metadata, formula) {
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    inds <- seq_len(ncol(mm) - 1)
    vars <- colnames(mm)[inds]

    fit_1 <- orm(abundance ~ ., data = mm)
    score_1 <- fit_1$stats["Score"]

    res <- data.frame(estimate = fit_1$coefficients[vars], p_value = NA)

    if (length(inds) == 1) {
        res$p_value <- fit_1$stats["Score P"]
    } else {
        for (i in inds) {
            fit_0 <- orm(abundance ~ ., data = mm[, -i])
            score_0 <- fit_0$stats["Score"]
            res$p_value[i] <- as.numeric(
                1 - pchisq(score_1 - score_0, df = 1)
            )
        }
    }

    res[["variable"]] <- rownames(res)
    rownames(res) <- NULL
    return(res)
}
