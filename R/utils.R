################################################################################
# Internal methods imported from mia
################################################################################

.is_a_bool <- mia:::.is_a_bool
.is_non_empty_string <- mia:::.is_non_empty_string
.is_non_empty_character <- mia:::.is_non_empty_character
.check_assay_present <- mia:::.check_assay_present
.check_and_get_altExp <- mia:::.check_and_get_altExp
.add_values_to_colData <- mia:::.add_values_to_colData

################################################################################
# Input validation - matching plotBoxplot's pattern
################################################################################

#' Check inputs for statistical tests
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment colData rowData
.check_input <- function(x, assay.type, row.var, col.var, formula,
                         split.by, pair.by, features) {
    # Either assay.type, row.var or col.var must be specified
    if (sum(c(is.null(assay.type), is.null(row.var), is.null(col.var))) != 2L) {
        stop("Please specify either 'assay.type', 'row.var', or 'col.var'.",
            call. = FALSE
        )
    }
    # features cannot be specified if row.var or col.var is specified
    if (is.null(assay.type) && !is.null(features)) {
        stop("'features' can only be specified when 'assay.type' is specified.",
            call. = FALSE
        )
    }
    # As features points to rownames, the TSE must have rownames
    if (!is.null(features) && is.null(rownames(x))) {
        stop("'x' must have rownames.", call. = FALSE)
    }
    if (!(is.null(features) ||
        (is.character(features) && all(features %in% rownames(x))))) {
        stop("'features' must be NULL or character vector specifying rownames.",
            call. = FALSE
        )
    }
    # If assay was specified, check that it is correct
    if (!is.null(assay.type)) {
        .check_assay_present(assay.type, x)
    }
    # Check row.var exists in rowData
    if (!is.null(row.var)) {
        if (!.is_non_empty_string(row.var)) {
            stop("'row.var' must be a single character value.", call. = FALSE)
        }
        if (!row.var %in% colnames(rowData(x))) {
            stop("'", row.var, "' not found in rowData(x).", call. = FALSE)
        }
    }
    # Check col.var exists in colData
    if (!is.null(col.var)) {
        if (!.is_non_empty_string(col.var)) {
            stop("'col.var' must be a single character value.", call. = FALSE)
        }
        if (!col.var %in% colnames(colData(x))) {
            stop("'", col.var, "' not found in colData(x).", call. = FALSE)
        }
    }
    # Check formula
    group <- .get_rhs_var(formula)
    # Check group variable exists in appropriate metadata
    .check_metadata_var(x, group, assay.type, row.var, col.var)
    # Check split.by variables
    if (!is.null(split.by)) {
        if (!is.character(split.by)) {
            stop("'split.by' must be a character vector.", call. = FALSE)
        }
        for (var in split.by) {
            .check_metadata_var(x, var, assay.type, row.var, col.var)
        }
    }
    # Check pair.by variable
    if (!is.null(pair.by)) {
        if (!.is_non_empty_string(pair.by)) {
            stop("'pair.by' must be a single character value.", call. = FALSE)
        }
        .check_metadata_var(x, pair.by, assay.type, row.var, col.var)
    }
    # Return group for use in caller
    group
}

#' Check metadata variable exists in appropriate location
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment colData rowData
.check_metadata_var <- function(x, var, assay.type, row.var, col.var) {
    # When assay.type or col.var is used, check colData
    # When row.var is used, check rowData
    if (!is.null(row.var)) {
        if (!var %in% colnames(rowData(x))) {
            stop("'", var, "' not found in rowData(x).", call. = FALSE)
        }
    } else {
        if (!var %in% colnames(colData(x))) {
            stop("'", var, "' not found in colData(x).", call. = FALSE)
        }
    }
    invisible(NULL)
}

#' Extract RHS variable from formula
#' @keywords internal
#' @noRd
.get_rhs_var <- function(formula) {
    if (!inherits(formula, "formula")) {
        stop("'formula' must be a formula.", call. = FALSE)
    }
    # Get RHS of formula (handles both ~ group and value ~ group)
    rhs <- as.character(formula)[length(as.character(formula))]
    if (length(rhs) != 1 || rhs == "") {
        stop("Formula must specify a grouping variable.", call. = FALSE)
    }
    rhs
}

#' Check group has at least 2 levels
#' @keywords internal
#' @noRd
.check_group <- function(df, group) {
    if (!group %in% names(df)) {
        stop("'", group, "' not found in data.", call. = FALSE)
    }
    vals <- unique(df[[group]])
    vals <- vals[!is.na(vals)]
    if (length(vals) < 2) {
        stop("'group' must have at least 2 levels. Found ", length(vals), ".",
            call. = FALSE
        )
    }
    invisible(NULL)
}

################################################################################
# Data extraction - matching plotBoxplot's approach
################################################################################

#' Get data for testing based on source
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment colData rowData
#' @importFrom mia meltSE
.get_data <- function(x, assay.type, row.var, col.var,
                      group, split.by, pair.by, features) {
    # Collect all variable names needed
    all_vars <- c(group, split.by, pair.by)
    all_vars <- unique(all_vars[!sapply(all_vars, is.null)])

    # Get data based on source - matching plotBoxplot's pattern
    if (!is.null(assay.type)) {
        # Subset features if specified
        if (!is.null(features)) {
            x <- x[features, , drop = FALSE]
        }
        # Use meltSE - column name is the assay.type
        df <- meltSE(x, assay.type = assay.type, add.col = all_vars)
    } else if (!is.null(row.var)) {
        # Get from rowData - column name is row.var
        df <- rowData(x)[, c(row.var, all_vars), drop = FALSE]
    } else {
        # Get from colData - column name is col.var
        df <- colData(x)[, c(col.var, all_vars), drop = FALSE]
    }

    df <- as.data.frame(df)
    attr(df, "pair.by") <- pair.by
    .check_group(df, group)
    df
}

################################################################################
# Universal DAA Engine
################################################################################

#' Unified engine for differential abundance analysis
#' @keywords internal
#' @noRd
#' @importFrom rstatix adjust_pvalue
#' @importFrom S4Vectors DataFrame
#' @importFrom dplyr across all_of group_split arrange
#' @importFrom purrr map_df
.calc_daa <- function(df, y, group, split.by, paired, FUN,
                      p.adjust.method = "fdr", ...) {
    # Identify pairing variable
    pair.by <- attr(df, "pair.by")

    # Combine grouping vars: FeatureID (from meltSE) + split.by
    grouping_vars <- c(split.by)
    if ("FeatureID" %in% names(df)) {
        grouping_vars <- c("FeatureID", grouping_vars)
    }

    # Build formula: y ~ group
    formula <- as.formula(paste0(y, " ~ ", group))

    # Run tests per group (FeatureID + split.by)
    if (length(grouping_vars) > 0) {
        res <- df |>
            group_split(across(all_of(grouping_vars))) |>
            map_df(function(sub_df) {
                # Ensure correct alignment for paired tests
                if (paired && !is.null(pair.by)) {
                    sub_df <- sub_df |> arrange(across(all_of(pair.by)))
                }

                # Run test with error handling
                test_res <- tryCatch(
                    {
                        FUN(sub_df, formula, paired = paired, ...)
                    },
                    error = function(e) {
                        # Print warning to terminal
                        msg <- conditionMessage(e)
                        warning("Statistical test failed for a feature: ", msg,
                            call. = FALSE
                        )
                        # Create empty/NA result with error message
                        out <- data.frame(
                            .y. = y,
                            group1 = NA_character_,
                            group2 = NA_character_,
                            n1 = NA_integer_,
                            n2 = NA_integer_,
                            statistic = NA_real_,
                            p = NA_real_,
                            warning = msg
                        )
                        return(out)
                    }
                )

                # Attach grouping info
                group_info <- sub_df[1, grouping_vars, drop = FALSE]
                res_with_groups <- cbind(test_res, group_info)
                return(res_with_groups)
            })
    } else {
        # Single test (no FeatureID/split.by)
        if (paired && !is.null(pair.by)) {
            df <- df |> arrange(across(all_of(pair.by)))
        }

        res <- tryCatch(
            {
                FUN(df, formula, paired = paired, ...)
            },
            error = function(e) {
                msg <- conditionMessage(e)
                warning("Statistical test failed: ", msg, call. = FALSE)
                out <- data.frame(
                    .y. = y,
                    group1 = NA_character_,
                    group2 = NA_character_,
                    n1 = NA_integer_,
                    n2 = NA_integer_,
                    statistic = NA_real_,
                    p = NA_real_,
                    warning = msg
                )
                return(out)
            }
        )
    }

    # P-value adjustment
    if ("p" %in% colnames(res) && any(!is.na(res$p))) {
        res <- res |> adjust_pvalue(method = p.adjust.method)
    } else {
        res$p.adj <- NA_real_
    }

    res <- DataFrame(res)
    return(res)
}
