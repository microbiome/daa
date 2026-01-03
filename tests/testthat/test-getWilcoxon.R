# Tests for getWilcoxon

# Use HintikkaXOData - has good variance for statistical tests
data(HintikkaXOData, package = "mia")
mae <- HintikkaXOData
tse <- MultiAssayExperiment::getWithColData(mae, "microbiota")
tse <- mia::transformAssay(tse, method = "relabundance")
tse <- tse[1:10, ]

################################################################################
# assay.type tests (per-feature)
################################################################################

test_that("getWilcoxon with assay.type returns DataFrame", {
    result <- getWilcoxon(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )

    expect_s4_class(result, "DataFrame")
    expect_true("p" %in% names(result))
    expect_true("p.adj" %in% names(result))
})

test_that("getWilcoxon with assay.type returns one row per feature", {
    result <- getWilcoxon(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )
    expect_equal(nrow(result), nrow(tse))
})

test_that("getWilcoxon respects features argument", {
    feat_subset <- rownames(tse)[1:5]
    result <- getWilcoxon(tse,
        assay.type = "relabundance",
        formula = ~Fat, features = feat_subset
    )
    expect_equal(nrow(result), 5)
})

################################################################################
# col.var tests (colData variable)
################################################################################

test_that("getWilcoxon with col.var works", {
    tse_alpha <- mia::addAlpha(tse, index = "shannon_diversity")
    result <- getWilcoxon(tse_alpha,
        col.var = "shannon_diversity",
        formula = ~Fat
    )

    expect_s4_class(result, "DataFrame")
    expect_equal(nrow(result), 1) # Single test, not per-feature
})

################################################################################
# Robustness tests
################################################################################

test_that("getWilcoxon handles sparse data with warnings", {
    # Create a feature with all NAs to trigger error
    tse_sparse <- tse
    assay(tse_sparse, "relabundance")[1, ] <- NA_real_

    expect_warning(
        result <- getWilcoxon(tse_sparse,
            assay.type = "relabundance",
            formula = ~Fat
        ),
        "failed"
    )
    expect_true(any(is.na(result$p)))
    expect_true("warning" %in% colnames(result))
})

test_that("getWilcoxon works with un-sorted paired data", {
    # Create paired data and shuffle it
    tse_paired <- tse[, 1:10]
    tse_paired$Subject <- rep(1:5, each = 2)
    tse_paired$Time <- rep(c("T1", "T2"), 5)

    # Shuffle
    idx <- sample(ncol(tse_paired))
    tse_shuffled <- tse_paired[, idx]

    # This should pass because we sort internally by Subject
    expect_silent(
        result <- getWilcoxon(tse_shuffled,
            assay.type = "relabundance",
            formula = ~Time, pair.by = "Subject"
        )
    )
    expect_s4_class(result, "DataFrame")
})

################################################################################
# Validation tests
################################################################################

test_that("getWilcoxon fails without data source", {
    expect_error(getWilcoxon(tse, formula = ~Fat), "either")
})

test_that("getWilcoxon fails with invalid formula", {
    expect_error(
        getWilcoxon(tse, assay.type = "relabundance", formula = "not a formula"),
        "must be a formula"
    )
})

test_that("getWilcoxon p.adjust.method parameter works", {
    result <- getWilcoxon(tse,
        assay.type = "relabundance",
        formula = ~Fat, p.adjust.method = "bonferroni"
    )
    expect_true("p.adj" %in% names(result))
})

################################################################################
# addWilcoxon tests
################################################################################

test_that("addWilcoxon adds p.adj to rowData", {
    result <- addWilcoxon(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )
    expect_true("wilcoxon_padj" %in% colnames(rowData(result)))
})
