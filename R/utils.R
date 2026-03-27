#' @importFrom rlang .data
NULL

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
.get_rhs_formula <- function(formula) {
    rhs_formula <- stats::terms(formula) |>
        stats::delete.response() |>
        stats::as.formula()
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

    is_assay <- lhs %in% SummarizedExperiment::assayNames(tse)
    is_coldata <- lhs %in% colnames(SummarizedExperiment::colData(tse))
    is_rowdata <- lhs %in% colnames(SummarizedExperiment::rowData(tse))

    if (is_assay) {
        df <- .merge_tse(tse, lhs)
    } else {
        FUN <- if (is_coldata) {
            SummarizedExperiment::colData
        } else if (is_rowdata) {
            SummarizedExperiment::rowData
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
    rd <- tse |> SummarizedExperiment::rowData()
    cd <- tse |> SummarizedExperiment::colData()
    mat <- tse |> SummarizedExperiment::assay(assay.type)

    mat <- mat |> as.data.frame()
    mat[["rownames"]] <- rownames(mat)

    mat <- tidyr::pivot_longer(
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
        dplyr::left_join(rd, by = "rownames") |>
        dplyr::left_join(cd, by = "colnames")

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
#' @importFrom dplyr group_by filter ungroup n_distinct arrange
.calculate_rstatix <- function(df, formula, FUN, pair.by = NULL, ...) {
    lhs <- .get_lhs(formula) |> rlang::sym()
    rhs <- .get_rhs(formula) |> rlang::sym()

    # Feature filtering: there must be variance, otherwise test will fail
    df <- df |>
        dplyr::group_by(.data[["rownames"]], !!rhs) |>
        dplyr::filter(
            dplyr::n_distinct(!!lhs) > 1,
            stats::var(!!lhs, na.rm = TRUE) > 0
        ) |>
        dplyr::ungroup()

    df <- df |>
        dplyr::group_by(.data[["rownames"]]) |>
        dplyr::filter(
            dplyr::n_distinct(!!rhs) >= 2
        )

    # Paired samples are controlled in rstatix with sorting
    if (!is.null(pair.by)) {
        df <- df |> dplyr::arrange(!!rlang::sym(pair.by))
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
        SummarizedExperiment::assayNames(tse),
        colnames(SummarizedExperiment::colData(tse))
    ))) {
        stop(
            "All formula variables must be in assayNames(x) or colData(x).",
            call. = FALSE
        )
    }

    is_assay <- lhs %in% SummarizedExperiment::assayNames(tse)
    if (is_assay) {
        lhs_df <- SummarizedExperiment::assay(tse, lhs)
    } else {
        lhs_df <- SummarizedExperiment::colData(tse)[, lhs, drop = FALSE] |>
            as.data.frame() |>
            t()
    }
    lhs_df <- lhs_df |> as.data.frame()

    rhs_df <- SummarizedExperiment::colData(tse)[, rhs, drop = FALSE] |>
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

################################################################################
# Limma calculator
################################################################################

#' @keywords internal
#' @noRd
.calculate_limma <- function(formula, mat, metadata) {
    if (!requireNamespace("limma", quietly = TRUE)) {
        stop(
            "Package 'limma' is required. ",
            "Install with: BiocManager::install('limma')",
            call. = FALSE
        )
    }
    rhs_formula <- .get_rhs_formula(formula)
    design_mat <- stats::model.matrix(rhs_formula, data = metadata)

    fit <- limma::lmFit(mat, design_mat)
    fit <- limma::eBayes(fit)
    return(fit)
}

################################################################################
# Per-feature model helpers
################################################################################

#' Create design matrix from formula (drop intercept)
#' @keywords internal
#' @noRd
.create_design_matrix <- function(formula, metadata) {
    formula <- .get_rhs_formula(formula)
    dm <- stats::model.matrix(formula, metadata) |>
        as.data.frame()
    dm[["(Intercept)"]] <- NULL
    return(dm)
}

#' Train a model per feature and bind results
#' @keywords internal
#' @noRd
#' @importFrom dplyr bind_rows mutate
.train_model_per_feature <- function(formula, mat, metadata, FUN) {
    feature_df <- mat |>
        t() |>
        as.data.frame()

    results <- lapply(feature_df, function(x) {
        FUN(x, metadata = metadata, formula = formula)
    })

    res <- dplyr::bind_rows(results, .id = "rownames") |>
        dplyr::mutate(
            q_value = stats::p.adjust(.data[["p_value"]], method = "BH")
        )
    return(res)
}

#' Run linear model per feature
#' @keywords internal
#' @noRd
.run_lm <- function(abundance, metadata, formula) {
    if (!requireNamespace("broom", quietly = TRUE)) {
        stop(
            "Package 'broom' is required. Install with: install.packages('broom')",
            call. = FALSE
        )
    }
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    fit <- stats::lm(abundance ~ ., data = mm)
    res <- broom::tidy(fit)

    res <- res[res$term != "(Intercept)", c("term", "estimate", "p.value"),
        drop = FALSE
    ]
    colnames(res) <- c("variable", "estimate", "p_value")
    rownames(res) <- NULL
    return(res)
}

#' Run ordinal regression model per feature
#' @keywords internal
#' @noRd
.run_orm <- function(abundance, metadata, formula) {
    if (!requireNamespace("rms", quietly = TRUE)) {
        stop(
            "Package 'rms' is required. Install with: install.packages('rms')",
            call. = FALSE
        )
    }
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    inds <- seq_len(ncol(mm) - 1)
    vars <- colnames(mm)[inds]

    fit_1 <- rms::orm(abundance ~ ., data = mm)
    score_1 <- fit_1$stats["Score"]

    res <- data.frame(estimate = fit_1$coefficients[vars], p_value = NA)

    if (length(inds) == 1) {
        res$p_value <- fit_1$stats["Score P"]
    } else {
        for (i in inds) {
            fit_0 <- rms::orm(abundance ~ ., data = mm[, -i])
            score_0 <- fit_0$stats["Score"]
            res$p_value[i] <- as.numeric(
                1 - stats::pchisq(score_1 - score_0, df = 1)
            )
        }
    }

    res[["variable"]] <- rownames(res)
    rownames(res) <- NULL
    return(res)
}

#' Run Firth logistic regression per feature
#' @keywords internal
#' @noRd
.run_firth <- function(abundance, metadata, formula) {
    if (!requireNamespace("logistf", quietly = TRUE)) {
        stop(
            "Package 'logistf' is required. ",
            "Install with: install.packages('logistf')",
            call. = FALSE
        )
    }
    mm <- .create_design_matrix(formula, metadata)
    mm <- cbind.data.frame(mm, abundance = abundance)

    fit <- logistf::logistf(
        abundance ~ .,
        data = mm,
        control = logistf::logistf.control(maxit = 1000)
    )

    res <- data.frame(
        estimate = fit$coefficients,
        p_value = fit$prob
    )

    res <- res[!rownames(res) %in% c("(Intercept)"), , drop = FALSE]
    res[["variable"]] <- rownames(res)
    rownames(res) <- NULL
    return(res)
}
