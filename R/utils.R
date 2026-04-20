################################################################################
# Formula helpers
################################################################################

#' @keywords internal
#' @noRd
.get_lhs <- function(formula) {
    all_vars <- all.vars(formula)
    lhs <- all_vars[[1L]]
    return(lhs)
}

#' @keywords internal
#' @noRd
.get_rhs <- function(formula) {
    all_vars <- all.vars(formula)
    rhs <- all_vars[-1L]
    return(rhs)
}

#' @keywords internal
#' @noRd
#' @importFrom stats as.formula delete.response terms
.get_rhs_formula <- function(formula) {
    rhs_formula <- terms(formula) |>
        delete.response() |>
        as.formula()
    return(rhs_formula)
}

################################################################################
# Long-format data helpers
################################################################################

#' Get long-format data from TSE based on formula
#'
#' Auto-detects whether the LHS of the formula is an assay, colData, or
#' rowData variable and returns a long-format data.frame.
#'
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment assayNames colData rowData assay
.get_long_data <- function(tse, formula, pair.by = NULL) {
    lhs <- .get_lhs(formula)

    is_assay <- lhs %in% assayNames(tse)
    is_coldata <- lhs %in% colnames(colData(tse))
    is_rowdata <- lhs %in% colnames(rowData(tse))

    if (is_assay) {
        df <- .merge_tse(tse, lhs)
    } else {
        FUN <- if (is_coldata) {
            colData
        } else if (is_rowdata) {
            rowData
        } else {
            stop(
                "'", lhs, "' not found in assayNames, colData, or rowData.",
                call. = FALSE
            )
        }
        df <- tse |> FUN()
        df <- as.data.frame(df)
        df[["colnames"]] <- rownames(df)
        df[["rownames"]] <- lhs
    }

    if (!is.numeric(df[[lhs]])) {
        stop("The dependent variable must be numeric.", call. = FALSE)
    }

    rhs <- .get_rhs(formula)
    all_vars <- c(lhs, rhs, pair.by)

    if (!all(all_vars %in% colnames(df))) {
        missing <- setdiff(all_vars, colnames(df))
        stop(
            "Variable(s) not found in the data: ",
            paste0("'", missing, "'", collapse = ", "),
            call. = FALSE
        )
    }

    df <- df[, c(all_vars, "colnames", "rownames"), drop = FALSE] |>
        as.data.frame()
    return(df)
}

#' Melt a TSE assay into long format and join with row/col metadata
#'
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment rowData colData assay
#' @importFrom tidyr pivot_longer
#' @importFrom dplyr left_join
.merge_tse <- function(tse, assay.type) {
    rd <- tse |> rowData()
    cd <- tse |> colData()
    mat <- tse |> assay(assay.type)

    mat <- mat |> as.data.frame()
    mat[["rownames"]] <- rownames(mat)

    mat <- pivot_longer(
        mat,
        cols = -"rownames",
        names_to = "colnames",
        values_to = assay.type
    )

    rd <- rd |> as.data.frame()
    rd[["rownames"]] <- rownames(rd)

    cd <- cd |> as.data.frame()
    cd[["colnames"]] <- rownames(cd)

    df <- mat |>
        left_join(rd, by = "rownames") |>
        left_join(cd, by = "colnames")

    return(df)
}

################################################################################
# Rstatix calculator
################################################################################

#' Run a rstatix test function on long-format data
#'
#' Groups by feature (rownames), filters low-variance features, then runs the
#' test per feature.
#'
#' @keywords internal
#' @noRd
#' @importFrom rlang sym !!
#' @importFrom rlang .data
#' @importFrom dplyr group_by filter ungroup n_distinct arrange
#' @importFrom stats var
.calculate_rstatix <- function(df, formula, FUN, pair.by = NULL, ...) {
    lhs <- .get_lhs(formula) |> sym()
    rhs <- .get_rhs(formula) |> sym()

    # Feature filtering: there must be variance, otherwise test will fail
    df <- df |>
        group_by(.data[["rownames"]], !!rhs) |>
        filter(
            n_distinct(!!lhs) > 1,
            var(!!lhs, na.rm = TRUE) > 0
        ) |>
        ungroup()

    df <- df |>
        group_by(.data[["rownames"]]) |>
        filter(
            n_distinct(!!rhs) >= 2
        )

    # Paired samples are controlled in rstatix with sorting
    if (!is.null(pair.by)) {
        df <- df |> arrange(!!sym(pair.by))
    }

    # Create argument list
    args <- list(
        data = df,
        formula = formula
    )
    if (!is.null(pair.by)) {
        args[["paired"]] <- TRUE
    }
    args <- c(args, list(...))

    # Call function
    res <- do.call(FUN, args)
    return(res)
}

#' Calculate effect size per feature from long-format data
#'
#' Currently supports Cliff's delta for unpaired two-group comparisons.
#'
#' @keywords internal
#' @noRd
#' @importFrom dplyr bind_rows n_distinct
#' @importFrom effsize cliff.delta
.calculate_effect_size <- function(df, formula, pair.by = NULL,
                                   effect_size = c("none", "cliff"), rownames_filter = NULL) {
    effect_size <- match.arg(effect_size)
    if (effect_size == "none") {
        return(NULL)
    }

    lhs <- .get_lhs(formula)
    rhs <- .get_rhs(formula)
    n_groups <- n_distinct(df[[rhs]], na.rm = TRUE)

    # Cliff's delta is defined here for unpaired two-group comparisons.
    if (!is.null(pair.by) || n_groups != 2L) {
        return(NULL)
    }

    if (!is.null(rownames_filter)) {
        df <- df[df$rownames %in% unique(rownames_filter), , drop = FALSE]
    }

    if (nrow(df) == 0L) {
        return(NULL)
    }

    delta_res <- lapply(split(df, df$rownames), function(.x) {
        .x <- .x[stats::complete.cases(.x[, c(lhs, rhs), drop = FALSE]), ,
            drop = FALSE
        ]
        if (nrow(.x) == 0L || n_distinct(.x[[rhs]], na.rm = TRUE) != 2L) {
            return(NULL)
        }
        cd <- cliff.delta(formula = formula, data = .x)
        data.frame(
            cliff_delta = unname(cd$estimate),
            cliff_delta_lower = cd$conf.int[1],
            cliff_delta_upper = cd$conf.int[2],
            cliff_delta_magnitude = unname(cd$magnitude)
        )
    })

    keep <- !vapply(delta_res, is.null, logical(1L))
    if (!any(keep)) {
        return(NULL)
    }

    delta_res <- bind_rows(delta_res[keep], .id = "rownames")
    return(delta_res)
}

################################################################################
# Wide-format data helper
################################################################################

#' Build wide-format data for model-based methods
#' @keywords internal
#' @noRd
#' @importFrom SummarizedExperiment assay colData assayNames
.get_wide_data <- function(tse, formula) {
    lhs <- .get_lhs(formula)
    rhs <- .get_rhs(formula)

    if (!all(c(lhs, rhs) %in% c(
        assayNames(tse),
        colnames(colData(tse))
    ))) {
        stop(
            "All formula variables must be in assayNames(x) or colData(x).",
            call. = FALSE
        )
    }

    is_assay <- lhs %in% assayNames(tse)
    if (is_assay) {
        lhs_df <- assay(tse, lhs)
    } else {
        lhs_df <- colData(tse)[, lhs, drop = FALSE] |>
            as.data.frame() |>
            t()
    }
    lhs_df <- lhs_df |> as.data.frame()

    rhs_df <- colData(tse)[, rhs, drop = FALSE] |>
        as.data.frame()

    if (!all(vapply(lhs_df, is.numeric, logical(1L)))) {
        stop("The dependent variable must be numeric.", call. = FALSE)
    }

    data_list <- list(
        matrix = lhs_df,
        sample_metadata = rhs_df
    )
    return(data_list)
}

#' Create design matrix from formula (drop intercept)
#' @keywords internal
#' @noRd
#' @importFrom stats model.matrix
.create_design_matrix <- function(formula, metadata) {
    formula <- .get_rhs_formula(formula)
    dm <- model.matrix(formula, metadata) |>
        as.data.frame()
    dm[["(Intercept)"]] <- NULL
    return(dm)
}

#' Train a model per feature and bind results
#' @keywords internal
#' @noRd
#' @importFrom dplyr bind_rows mutate
#' @importFrom rlang .data
#' @importFrom stats p.adjust
.train_model_per_feature <- function(formula, mat, metadata, FUN,
                                     p_adjust_method = "BH") {
    feature_df <- mat |>
        t() |>
        as.data.frame()

    results <- lapply(feature_df, function(x) {
        FUN(x, metadata = metadata, formula = formula)
    })

    res <- bind_rows(results, .id = "rownames")
    if (!is.null(p_adjust_method)) {
        res <- res |>
            mutate(
                q_value = p.adjust(.data[["p_value"]], method = p_adjust_method)
            )
    }
    return(res)
}
