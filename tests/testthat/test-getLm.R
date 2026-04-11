# Tests for getLm
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::transformAssay(tse, method = "pa")
tse <- mia::transformAssay(tse, method = "rclr")

test_that("getLm returns data frame", {
    skip_if_not_installed("broom")
    res <- getLm(tse, rclr ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true(all(c("rownames", "variable", "estimate", "p_value", "q_value") %in% names(res)))
})
