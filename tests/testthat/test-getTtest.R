# Tests for getTtest

# Use HintikkaXOData - has good variance for statistical tests
# Need getWithColData to get colData from MAE
data(HintikkaXOData, package = "mia")
mae <- HintikkaXOData
tse <- MultiAssayExperiment::getWithColData(mae, "microbiota")
tse <- mia::transformAssay(tse, method = "relabundance")
tse <- tse[1:10, ]

################################################################################
# assay.type tests (per-feature)
################################################################################

test_that("getTtest with assay.type returns DataFrame", {
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )

    expect_s4_class(result, "DataFrame")
    expect_true("p" %in% names(result))
    expect_true("p.adj" %in% names(result))
})

test_that("getTtest with assay.type returns one row per feature", {
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )
    expect_equal(nrow(result), nrow(tse))
})

test_that("getTtest respects features argument", {
    feat_subset <- rownames(tse)[1:5]
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat, features = feat_subset
    )
    expect_equal(nrow(result), 5)
})

################################################################################
# col.var tests (colData variable)
################################################################################

test_that("getTtest with col.var works", {
    tse_alpha <- mia::addAlpha(tse)
    result <- getTtest(tse_alpha,
        col.var = "shannon_diversity",
        formula = ~Fat
    )

    expect_s4_class(result, "DataFrame")
    expect_equal(nrow(result), 1) # Single test, not per-feature
})

################################################################################
# Validation tests
################################################################################

test_that("getTtest fails without data source", {
    expect_error(getTtest(tse, formula = ~Fat), "either")
})

test_that("getTtest fails with invalid formula", {
    expect_error(
        getTtest(tse, assay.type = "relabundance", formula = "not a formula"),
        "must be a formula"
    )
})

test_that("getTtest var.equal parameter works", {
    result_welch <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat, var.equal = FALSE
    )
    result_student <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat, var.equal = TRUE
    )
    expect_true(is.numeric(result_welch$p))
    expect_true(is.numeric(result_student$p))
})

################################################################################
# Robustness tests
################################################################################

test_that("getTtest handles zero variance with warnings", {
    # Create a feature with zero variance to trigger error in t-test
    tse_sparse <- tse
    assay(tse_sparse, "relabundance")[1, ] <- 1 # All same values

    expect_warning(
        result <- getTtest(tse_sparse,
            assay.type = "relabundance",
            formula = ~Fat
        ),
        "failed"
    )
    expect_true(any(is.na(result$p)))
    expect_true("warning" %in% colnames(result))
})

test_that("getTtest works with un-sorted paired data", {
    # Create paired data and shuffle it
    tse_paired <- tse[, 1:10]
    tse_paired$Subject <- rep(1:5, each = 2)
    tse_paired$Time <- rep(c("T1", "T2"), 5)

    # Shuffle
    idx <- sample(ncol(tse_paired))
    tse_shuffled <- tse_paired[, idx]

    # This should pass because we sort internally by Subject
    expect_silent(
        result <- getTtest(tse_shuffled,
            assay.type = "relabundance",
            formula = ~Time, pair.by = "Subject"
        )
    )
    expect_s4_class(result, "DataFrame")
})

test_that("getTtest p.adjust.method parameter works", {
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat, p.adjust.method = "bonferroni"
    )
    expect_true("p.adj" %in% names(result))
})

################################################################################
# addTtest tests
################################################################################

test_that("addTtest adds p.adj to rowData", {
    result <- addTtest(tse,
        assay.type = "relabundance",
        formula = ~Fat
    )
    expect_true("ttest_padj" %in% colnames(rowData(result)))
})
