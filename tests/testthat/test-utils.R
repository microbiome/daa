# Tests for utils.R functions
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::addAlpha(tse, index = "shannon")

################################################################################
# .get_lhs / .get_rhs tests
################################################################################

test_that(".get_lhs extracts LHS variable", {
    expect_equal(.get_lhs(counts ~ Group), "counts")
    expect_equal(.get_lhs(shannon ~ Group), "shannon")
})

test_that(".get_rhs extracts RHS variables", {
    expect_equal(.get_rhs(counts ~ Group), "Group")
    expect_equal(.get_rhs(counts ~ A + B), c("A", "B"))
})

################################################################################
# .get_long_data tests
################################################################################

test_that(".get_long_data with assay returns correct format", {
    df <- .get_long_data(tse, counts ~ Geographical_location)
    expect_s3_class(df, "data.frame")
    expect_true("counts" %in% names(df))
    expect_true("Geographical_location" %in% names(df))
    expect_true("rownames" %in% names(df))
    expect_true("colnames" %in% names(df))
})

test_that(".get_long_data with colData returns correct format", {
    df <- .get_long_data(tse, shannon ~ Geographical_location)
    expect_s3_class(df, "data.frame")
    expect_true("shannon" %in% names(df))
    expect_true("Geographical_location" %in% names(df))
})

test_that(".get_long_data errors on missing variable", {
    expect_error(
        .get_long_data(tse, nonexistent ~ Geographical_location),
        "not found"
    )
})

################################################################################
# .get_wide_data tests
################################################################################

test_that(".get_wide_data returns matrix and metadata", {
    data_list <- .get_wide_data(tse, counts ~ Geographical_location)
    expect_true(is.list(data_list))
    expect_true("matrix" %in% names(data_list))
    expect_true("sample_metadata" %in% names(data_list))
    expect_true(is.data.frame(data_list$matrix))
    expect_true(is.data.frame(data_list$sample_metadata))
})
