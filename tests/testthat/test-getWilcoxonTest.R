# Tests for getWilcoxonTest
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::addAlpha(tse, index = "shannon")

test_that("getWilcoxonTest with assay works", {
    res <- getWilcoxonTest(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true("p" %in% names(res))
    expect_false("cliff_delta" %in% names(res))
})

test_that("getWilcoxonTest with colData variable works", {
    res <- getWilcoxonTest(tse, shannon ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_false("cliff_delta" %in% names(res))
})

test_that("getWilcoxonTest adds Cliff's delta for unpaired two-group comparisons", {
    tse_two <- tse[, tse$Geographical_location %in% c("Ahmednagar", "Nashik")]
    res <- getWilcoxonTest(tse_two, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true(all(c(
        "cliff_delta",
        "cliff_delta_lower",
        "cliff_delta_upper",
        "cliff_delta_magnitude"
    ) %in% names(res)))
})
