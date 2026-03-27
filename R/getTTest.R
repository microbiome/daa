#' @title Perform t-test
#'
#' @description
#' Performs t-test to compare values between two groups.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the variable to test
#'   (assay name, colData, or rowData variable) and the RHS specifies the
#'   grouping variable, e.g., \code{counts ~ Group}.
#' @param pair.by \code{Character scalar} or \code{NULL}. Column for pairing
#'   samples in paired tests. (Default: \code{NULL})
#' @param ... Additional arguments passed to \code{rstatix::t_test}.
#'
#' @return A \code{data.frame} with test results.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getTTest(tse, counts ~ Geographical_location)
#'
#' @importFrom rstatix t_test
#' @export
getTTest <- function(tse, formula, pair.by = NULL, ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    df <- .get_long_data(tse, formula, pair.by)
    res <- .calculate_rstatix(
        df = df, formula = formula,
        pair.by = pair.by, FUN = rstatix::t_test, ...
    )
    return(res)
}
