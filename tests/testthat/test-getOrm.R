# Tests for getOrm
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::transformAssay(tse, method = "pa")
tse <- mia::transformAssay(tse, method = "rclr")

test_that("getOrm returns data frame", {
    res <- getOrm(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true(all(c("rownames", "variable", "estimate", "p_value", "q_value") %in% names(res)))
})

test_that("getOrm allows disabling p-value adjustment", {
    res <- getOrm(tse, counts ~ Geographical_location, p_adjust_method = NULL)
    expect_s3_class(res, "data.frame")
    expect_false("q_value" %in% names(res))
})
