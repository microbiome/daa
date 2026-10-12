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
#' @param effect.size \code{NULL} or \code{Character scalar}. If
#'   \code{"cliff"} or \code{"cohen"}, the effect size from
#'   \code{\link{getEffectSize}} is added to the results. Not supported for
#'   paired tests. (Default: \code{NULL})
#' @param ... Additional arguments passed to \code{wilcox_test}.
#'
#' @return A \code{data.frame} with test results.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getWilcoxonTest(tse, counts ~ Geographical_location)
#'
#' # Add Cliff's delta
#' res <- getWilcoxonTest(
#'     tse, counts ~ Geographical_location,
#'     effect.size = "cliff"
#' )
#'
#' @importFrom rstatix wilcox_test
#' @importFrom dplyr left_join
#' @export
getWilcoxonTest <- function(tse, formula, pair.by = NULL, effect.size = NULL, ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    if (!is.null(effect.size)) {
        if (!is.null(pair.by)) {
            stop("'effect.size' is not supported for paired tests.",
                call. = FALSE
            )
        }
        effect.size <- match.arg(effect.size, c("cliff", "cohen"))
    }
    df <- .get_long_data(tse, formula, pair.by)
    res <- .calculate_rstatix(
        df = df, formula = formula,
        pair.by = pair.by, FUN = wilcox_test, ...
    )
    if (!is.null(effect.size)) {
        # Only groups that were tested for each feature
        rhs <- .get_rhs(formula)
        tested <- c(
            paste(res[["rownames"]], res[["group1"]]),
            paste(res[["rownames"]], res[["group2"]])
        )
        df <- df[paste(df[["rownames"]], df[[rhs]]) %in% tested, ,
            drop = FALSE
        ]
        es <- .calculate_effect_size(df, formula, effect.size)
        res <- left_join(res, es, by = c("rownames", "group1", "group2"))
    }
    return(res)
}
