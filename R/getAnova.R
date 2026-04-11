#' @title Perform ANOVA
#'
#' @description
#' Performs ANOVA to compare values between two or more groups.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the variable to test
#'   (assay name, colData, or rowData variable) and the RHS specifies the
#'   grouping variable, e.g., \code{counts ~ Group}.
#' @param ... Additional arguments passed to \code{anova_test}.
#'
#' @return A \code{data.frame} with test results.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getAnova(tse, counts ~ Geographical_location)
#'
#' @importFrom rstatix anova_test
#' @export
getAnova <- function(tse, formula, ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    df <- .get_long_data(tse, formula)
    res <- .calculate_rstatix(
        df = df, formula = formula,
        FUN = anova_test, ...
    )
    return(res)
}
