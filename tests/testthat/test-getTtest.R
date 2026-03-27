# Tests for getTTest
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::addAlpha(tse, index = "shannon")

test_that("getTTest with assay works", {
    res <- getTTest(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true("p" %in% names(res))
})

test_that("getTTest with colData variable works", {
    res <- getTTest(tse, shannon ~ Geographical_location)
    expect_s3_class(res, "data.frame")
})

test_that("getTTest fails with multiple RHS vars", {
    expect_error(
        getTTest(tse, counts ~ Geographical_location + Age),
        "exactly one"
    )
})
