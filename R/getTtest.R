#' @name
#' getTtest
#'
#' @title
#' Perform t-test
#'
#' @description
#' These functions perform t-test to compare values between two groups.
#'
#' @details
#' By default, Welch's t-test is used which does not assume equal variances.
#' Set \code{var.equal = TRUE} for Student's t-test.
#'
#' Specify exactly one of \code{assay.type}, \code{row.var}, or \code{col.var}
#' to define the values to test.
#'
#' @return
#' \code{getTtest} returns a \code{DataFrame} with test results.
#' \code{addTtest} returns \code{x} with results added to
#' \code{metadata(x)}.
#'
#' @param x A \code{SummarizedExperiment} object.
#'
#' @param assay.type \code{Character scalar} or \code{NULL}. Specifies assay to
#' test. Tests are run per feature. (Default: \code{NULL})
#'
#' @param row.var \code{Character scalar} or \code{NULL}. Specifies variable
#' from \code{rowData(x)} to test. (Default: \code{NULL})
#'
#' @param col.var \code{Character scalar} or \code{NULL}. Specifies variable
#' from \code{colData(x)} to test. (Default: \code{NULL})
#'
#' @param formula \code{formula}. A formula specifying the grouping variable,
#' e.g., \code{~ SampleType}. The RHS specifies the comparison groups.
#' For >2 levels, pairwise comparisons are performed.
#'
#' @param split.by \code{Character vector} or \code{NULL}. Columns to split by.
#' Tests are run separately for each combination. (Default: \code{NULL})
#'
#' @param pair.by \code{Character scalar} or \code{NULL}. Column for pairing
#' samples in paired tests. (Default: \code{NULL})
#'
#' @param features \code{Character vector} or \code{NULL}. Specific features
#' to test when using \code{assay.type}. (Default: \code{NULL})
#'
#' @param var.equal \code{Logical scalar}. Assume equal variances?
#' (Default: \code{FALSE})
#'
#' @param p.adjust.method \code{Character scalar}. Method for p-value
#' adjustment. (Default: \code{"fdr"})
#'
#' @param name \code{Character scalar}. Column name prefix for results.
#' (Default: \code{"ttest"})
#'
#' @param ... Additional arguments passed to \code{rstatix::t_test}.
#'
#' @examples
#' data(GlobalPatterns, package = "mia")
#' tse <- GlobalPatterns
#' tse <- tse[1:50, tse$SampleType %in% c("Feces", "Skin")]
#' grp <- as.character(tse$SampleType)
#' assay_mat <- SummarizedExperiment::assay(tse, "counts")
#' keep <- apply(assay_mat, 1, function(v) {
#'   a <- v[grp == "Feces"]
#'   b <- v[grp == "Skin"]
#'   !(stats::var(a, na.rm = TRUE) == 0 && stats::var(b, na.rm = TRUE) == 0)
#' })
#' tse <- tse[keep, ]
#'
#' # Test assay values (per feature)
#' res <- getTtest(tse, assay.type = "counts", formula = ~SampleType)
#'
#' # Test colData variable (e.g., alpha diversity)
#' tse$numeric_col <- as.numeric(seq_len(ncol(tse)))
#' res <- getTtest(tse, col.var = "numeric_col", formula = ~SampleType)
#'
#' @seealso
#' \code{\link[rstatix:t_test]{rstatix::t_test}},
#' \code{\link[daa:getWilcoxon]{getWilcoxon}}
#'
#' @export
NULL

#' @rdname getTtest
#' @export
#' @importFrom SingleCellExperiment altExp
#' @importFrom methods callNextMethod
setMethod("getTtest", "SingleCellExperiment", function(x, ...) {
    x <- .check_and_get_altExp(x, ...)
    res <- callNextMethod(x, ...)
    return(res)
})

#' @rdname getTtest
#' @export
#' @importFrom SummarizedExperiment assay colData rowData
#' @importFrom rstatix t_test adjust_pvalue
#' @importFrom S4Vectors DataFrame
setMethod(
    "getTtest", "SummarizedExperiment",
    function(x, assay.type = NULL, row.var = NULL, col.var = NULL,
             formula, split.by = NULL, pair.by = NULL, features = NULL,
             var.equal = FALSE, p.adjust.method = "fdr", ...) {
        ############################# Input check ##############################
        group <- .check_input(
            x, assay.type, row.var, col.var, formula,
            split.by, pair.by, features
        )
        if (!.is_a_bool(var.equal)) {
            stop("'var.equal' must be TRUE or FALSE.", call. = FALSE)
        }
        ########################### Input check end ############################
        # Get y variable name (the column to test)
        y <- c(assay.type, row.var, col.var)
        # Get data based on source
        df <- .get_data(
            x, assay.type, row.var, col.var, group,
            split.by, pair.by, features
        )
        # Run tests
        paired <- !is.null(pair.by)
        res <- .run_ttest(
            df, y, group, split.by, paired, var.equal,
            p.adjust.method, features, ...
        )
        return(res)
    }
)

#' @rdname getTtest
#' @export
setMethod(
    "addTtest", "SummarizedExperiment",
    function(x, name = "ttest", ...) {
        if (!.is_non_empty_string(name)) {
            stop("'name' must be a single character value.", call. = FALSE)
        }
        res <- getTtest(x, ...)
        S4Vectors::metadata(x)[[name]] <- res
        return(x)
    }
)

################################################################################
# Internal function using .calc_daa engine
################################################################################

#' @importFrom rstatix t_test
.run_ttest <- function(df, y, group, split.by, paired, var.equal,
                       p.adjust.method, features = NULL, ...) {
    .calc_daa(
        df = df, y = y, group = group, split.by = split.by,
        paired = paired, FUN = rstatix::t_test,
        p.adjust.method = p.adjust.method, features = features, var.equal = var.equal, ...
    )
}
