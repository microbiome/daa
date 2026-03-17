# Tests for getTtest

# Use GlobalPatterns - stable data for statistical tests
data(GlobalPatterns, package = "mia")
tse <- GlobalPatterns
tse <- mia::transformAssay(tse, method = "relabundance")
tse <- tse[, tse$SampleType %in% c("Feces", "Skin")]
grp <- as.character(tse$SampleType)
levels_grp <- unique(grp)
assay_mat <- SummarizedExperiment::assay(tse, "relabundance")
keep_feat <- apply(assay_mat, 1, function(v) {
    a <- v[grp == levels_grp[1]]
    b <- v[grp == levels_grp[2]]
    sum(!is.na(a)) >= 2 && sum(!is.na(b)) >= 2 &&
        stats::var(a, na.rm = TRUE) > 0 && stats::var(b, na.rm = TRUE) > 0
})
tse <- tse[which(keep_feat)[1:10], ]
tse$numeric_col <- as.numeric(seq_len(ncol(tse)))

################################################################################
# assay.type tests (per-feature)
################################################################################

test_that("getTtest with assay.type returns DataFrame", {
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~SampleType
    )

    expect_s4_class(result, "DataFrame")
    expect_true("p" %in% names(result))
    expect_true("p.adj" %in% names(result))
})

test_that("getTtest with assay.type returns one row per feature", {
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~SampleType
    )
    expect_equal(nrow(result), nrow(tse))
})

test_that("getTtest respects features argument", {
    feat_subset <- rownames(tse)[1:5]
    result <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~SampleType, features = feat_subset
    )
    expect_equal(nrow(result), 5)
})

################################################################################
# col.var tests (colData variable)
################################################################################

test_that("getTtest with col.var works", {
    result <- getTtest(tse,
        col.var = "numeric_col",
        formula = ~SampleType
    )

    expect_s4_class(result, "DataFrame")
    expect_equal(nrow(result), 1) # Single test, not per-feature
})

################################################################################
# Validation tests
################################################################################

test_that("getTtest fails without data source", {
    expect_error(getTtest(tse, formula = ~SampleType), "either")
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
        formula = ~SampleType, var.equal = FALSE
    )
    result_student <- getTtest(tse,
        assay.type = "relabundance",
        formula = ~SampleType, var.equal = TRUE
    )
    expect_true(is.numeric(result_welch$p))
    expect_true(is.numeric(result_student$p))
})

################################################################################
# Robustness tests
################################################################################

test_that("getTtest fails for zero-variance features", {
    # Create a feature with zero variance to trigger error in t-test
    tse_sparse <- tse
    assay(tse_sparse, "relabundance")[1, ] <- 1 # All same values

    expect_error(
        getTtest(tse_sparse,
            assay.type = "relabundance",
            formula = ~SampleType
        )
    )
})

test_that("getTtest works with un-sorted paired data", {
    # Create paired data and shuffle it
    n <- floor(ncol(tse) / 2) * 2
    tse_paired <- tse[, seq_len(n)]
    tse_paired$Subject <- rep(seq_len(n / 2), each = 2)
    tse_paired$Time <- rep(c("T1", "T2"), n / 2)

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
        formula = ~SampleType, p.adjust.method = "bonferroni"
    )
    expect_true("p.adj" %in% names(result))
})

################################################################################
# addTtest tests
################################################################################

test_that("addTtest stores results in metadata", {
    result <- addTtest(tse,
        assay.type = "relabundance",
        formula = ~SampleType
    )
    expect_true("ttest" %in% names(S4Vectors::metadata(result)))
    expect_s4_class(S4Vectors::metadata(result)$ttest, "DataFrame")
})
