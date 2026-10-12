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

test_that("getWilcoxonTest adds effect sizes for each comparison", {
    res <- getWilcoxonTest(
        tse, counts ~ Geographical_location,
        effect.size = "cliff"
    )
    es <- getEffectSize(tse, counts ~ Geographical_location)
    merged <- merge(
        as.data.frame(res)[, c("rownames", "group1", "group2", "effsize")],
        es[, c("rownames", "group1", "group2", "effsize")],
        by = c("rownames", "group1", "group2")
    )

    expect_equal(nrow(merged), nrow(res))
    expect_equal(merged$effsize.x, merged$effsize.y)
})

test_that("getWilcoxonTest rejects effect sizes for paired tests", {
    expect_error(
        getWilcoxonTest(
            tse, counts ~ Gender,
            pair.by = "Diet", effect.size = "cliff"
        ),
        "not supported for paired tests"
    )
})
