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
#' @param ... Additional arguments passed to \code{wilcox_test}.
#'
#' @return A \code{data.frame} with test results. For unpaired two-group
#'   comparisons with non-empty results, the output also includes Cliff's delta
#'   effect size columns.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getWilcoxonTest(tse, counts ~ Geographical_location)
#'
#' @importFrom dplyr bind_rows left_join n_distinct
#' @importFrom effsize cliff.delta
#' @importFrom rstatix wilcox_test
#' @export
getWilcoxonTest <- function(tse, formula, pair.by = NULL, ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    df <- .get_long_data(tse, formula, pair.by)
    res <- .calculate_rstatix(
        df = df, formula = formula,
        pair.by = pair.by, FUN = wilcox_test, ...
    )
    lhs <- .get_lhs(formula)
    rhs <- .get_rhs(formula)
    n_groups <- n_distinct(df[[rhs]], na.rm = TRUE)

    if (is.null(pair.by) && n_groups == 2L && nrow(res) > 0L) {
        df_delta <- df[df$rownames %in% unique(res$rownames), , drop = FALSE]
        delta_res <- lapply(split(df_delta, df_delta$rownames), function(.x) {
            .x <- .x[stats::complete.cases(.x[, c(lhs, rhs), drop = FALSE]), ,
                drop = FALSE
            ]
            cd <- cliff.delta(formula = formula, data = .x)
            data.frame(
                cliff_delta = unname(cd$estimate),
                cliff_delta_lower = cd$conf.int[1],
                cliff_delta_upper = cd$conf.int[2],
                cliff_delta_magnitude = unname(cd$magnitude)
            )
        }) |>
            bind_rows(.id = "rownames")
        res <- left_join(res, delta_res, by = "rownames")
    }
    return(res)
}
