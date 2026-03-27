# Tests for getWilcoxonTest
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::addAlpha(tse, index = "shannon")

test_that("getWilcoxonTest with assay works", {
    res <- getWilcoxonTest(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true("p" %in% names(res))
})

test_that("getWilcoxonTest with colData variable works", {
    res <- getWilcoxonTest(tse, shannon ~ Geographical_location)
    expect_s3_class(res, "data.frame")
})
