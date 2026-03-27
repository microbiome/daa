# Tests for getAnova and getKruskal
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")

test_that("getAnova with assay works", {
    res <- getAnova(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
})

test_that("getKruskal with assay works", {
    res <- getKruskal(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true("p" %in% names(res))
})
