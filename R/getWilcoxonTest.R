#' @title Perform Wilcoxon rank-sum test
#'
#' @description
#' Performs Wilcoxon rank-sum test (Mann-Whitney U) to compare values between
#' two groups.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the variable to test
#'   (assay name, colData, or rowData variable) and the RHS specifies the
#'   grouping variable, e.g., \code{counts ~ Group}.
#' @param pair.by \code{Character scalar} or \code{NULL}. Column for pairing
#'   samples in paired tests. (Default: \code{NULL})
#' @param effect_size \code{Character scalar}. Effect size to compute.
#'   Supported values are \code{"none"}, \code{"cliff"}, and \code{"cohen"}.
#'   (Default: \code{"none"})
#' @param ... Additional arguments passed to \code{wilcox_test}.
#'
#' @return A \code{data.frame} with test results. If
#'   \code{effect_size = "cliff"} or \code{"cohen"} and the comparison is
#'   unpaired with exactly two groups, output also includes effect size columns.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getWilcoxonTest(tse, counts ~ Geographical_location)
#'
#' @importFrom dplyr left_join
#' @importFrom rstatix wilcox_test
#' @export
getWilcoxonTest <- function(tse, formula, pair.by = NULL,
    effect_size = c("none", "cliff", "cohen"), ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    effect_size <- match.arg(effect_size)

    df <- .get_long_data(tse, formula, pair.by)
    res <- .calculate_rstatix(
        df = df, formula = formula,
        pair.by = pair.by, FUN = wilcox_test, ...
    )

    if (effect_size != "none") {
        # Only compute effect sizes for unpaired two-group comparisons.
        rhs <- .get_rhs(formula)
        n_groups <- sum(!is.na(unique(df[[rhs]])))
        if (is.null(pair.by) && n_groups == 2L) {
            # Pre-filter tse to only tested features to avoid computing effect sizes
            # for features without test results.
            if (length(res$rownames) > 0L) {
                tse_sub <- tse[res$rownames, , drop = FALSE]
            } else {
                tse_sub <- tse[0, , drop = FALSE]
            }

            delta_res <- getEffectSize(
                tse = tse_sub,
                formula = formula,
                method = effect_size,
                pair.by = pair.by
            )
            if (!is.null(delta_res)) {
                res <- left_join(res, delta_res, by = "rownames")
            }
        }
    }
    return(res)
}
