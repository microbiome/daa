#' @title Calculate effect sizes between groups
#'
#' @description
#' Calculates effect sizes between each pair of groups with Cliff's delta or
#' Cohen's d.
#'
#' @details
#' Cliff's delta is a non-parametric effect size based on how often values in
#' one group are larger than values in the other. Cohen's d is the difference
#' in means scaled by the pooled standard deviation. Both are calculated with
#' the \code{effsize} package.
#'
#' Groups are compared pairwise in the same order as in
#' \code{\link{getWilcoxonTest}}. Positive values mean that values are higher
#' in \code{group1} than in \code{group2}.
#'
#' @param tse A \code{SummarizedExperiment} object.
#' @param formula A formula where the LHS specifies the variable to test
#'   (assay name, colData, or rowData variable) and the RHS specifies the
#'   grouping variable, e.g., \code{counts ~ Group}.
#' @param method \code{Character scalar}. Effect size to calculate,
#'   \code{"cliff"} or \code{"cohen"}. (Default: \code{"cliff"})
#' @param ... Additional arguments passed to \code{effsize::cliff.delta} or
#'   \code{effsize::cohen.d}.
#'
#' @return A \code{data.frame} with one row per feature and pair of groups,
#'   and columns \code{rownames}, \code{group1}, \code{group2},
#'   \code{effsize}, \code{conf.low}, \code{conf.high} and \code{magnitude}.
#'
#' @examples
#' data(peerj13075, package = "mia")
#' tse <- peerj13075
#' tse <- mia::agglomerateByRank(tse, "phylum")
#' res <- getEffectSize(tse, counts ~ Geographical_location)
#'
#' @seealso
#' \code{\link[effsize:cliff.delta]{effsize::cliff.delta}},
#' \code{\link[effsize:cohen.d]{effsize::cohen.d}}
#'
#' @export
getEffectSize <- function(tse, formula, method = c("cliff", "cohen"), ...) {
    if (length(all.vars(formula[[3]])) != 1L) {
        stop("Formula RHS must specify exactly one grouping variable.",
            call. = FALSE
        )
    }
    method <- match.arg(method)
    df <- .get_long_data(tse, formula)
    res <- .calculate_effect_size(df, formula, method, ...)
    return(res)
}

#' Calculate effect size for each feature and pair of groups
#'
#' @keywords internal
#' @noRd
#' @importFrom effsize cliff.delta cohen.d
#' @importFrom utils combn
.calculate_effect_size <- function(df, formula, method, ...) {
    lhs <- .get_lhs(formula)
    rhs <- .get_rhs(formula)
    FUN <- switch(method, cliff = cliff.delta, cohen = cohen.d)
    # Pair groups in the same order as rstatix does
    group <- df[[rhs]]
    groups <- if (is.factor(group)) levels(droplevels(group)) else
        sort(unique(group))
    if (length(groups) < 2L) {
        stop("'", rhs, "' must have at least two groups.", call. = FALSE)
    }
    pairs <- combn(as.character(groups), 2L, simplify = FALSE)
    # Calculate effect size for each feature and pair of groups
    res <- lapply(split(df, df[["rownames"]]), function(feat) {
        feat_res <- lapply(pairs, function(pair) {
            keep <- feat[[rhs]] %in% pair & !is.na(feat[[lhs]])
            values <- feat[[lhs]][keep]
            groups <- factor(feat[[rhs]][keep], levels = pair)
            res <- data.frame(
                rownames = feat[["rownames"]][[1L]],
                group1 = pair[[1L]],
                group2 = pair[[2L]],
                effsize = NA_real_,
                conf.low = NA_real_,
                conf.high = NA_real_,
                magnitude = NA_character_
            )
            # Effect size cannot be calculated if a group has no values
            if (any(table(groups) == 0L)) {
                return(res)
            }
            es <- FUN(values, groups, ...)
            res[["effsize"]] <- unname(es[["estimate"]])
            res[["conf.low"]] <- es[["conf.int"]][[1L]]
            res[["conf.high"]] <- es[["conf.int"]][[2L]]
            res[["magnitude"]] <- as.character(es[["magnitude"]])
            return(res)
        })
        do.call(rbind, feat_res)
    })
    res <- do.call(rbind, res)
    rownames(res) <- NULL
    return(res)
}
