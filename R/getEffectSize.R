## Helper for effect size calculations

#' Calculate effect sizes for features in a SummarizedExperiment
#'
#' Wrapper that computes per-feature effect sizes from long-format data.
#'
#' @param tse A SummarizedExperiment-like object.
#' @param formula A formula where LHS is feature/assay and RHS grouping.
#' @param method Character scalar, one of 'cliff' or 'cohen'.
#' @param pair.by Optional pairing column name (passed to .get_long_data).
#' @return A data.frame with a `rownames` column and method-specific columns.
#' @keywords internal
#' @noRd
getEffectSize <- function(tse, formula, method = c("cliff", "cohen"),
                          pair.by = NULL) {
    method <- match.arg(method)
    df <- .get_long_data(tse, formula, pair.by)

    if (exists(".calculate_effect_size", mode = "function")) {
        return(.calculate_effect_size(
            df = df,
            formula = formula,
            pair.by = pair.by,
            effect_size = method
        ))
    }

    return(NULL)
}
