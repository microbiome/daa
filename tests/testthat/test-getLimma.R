# Tests for getLimma
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::transformAssay(tse, method = "pa")
tse <- mia::transformAssay(tse, method = "rclr")

test_that("getLimma returns fitted object", {
    skip_if_not_installed("limma")
    fit <- getLimma(tse, counts ~ Geographical_location)
    expect_true(is.list(fit))
})
