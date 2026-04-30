# Tests for getWilcoxonTest
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")
tse <- mia::addAlpha(tse, index = "shannon")

test_that("getWilcoxonTest with assay works", {
    res <- getWilcoxonTest(tse, counts ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_true("p" %in% names(res))
    expect_false("effect_size" %in% names(res))
})

test_that("getWilcoxonTest with colData variable works", {
    res <- getWilcoxonTest(tse, shannon ~ Geographical_location)
    expect_s3_class(res, "data.frame")
    expect_false("effect_size" %in% names(res))
})

test_that("getWilcoxonTest adds effect size for unpaired two-group comparisons", {
    tse_two <- tse[, tse$Geographical_location %in% c("Ahmednagar", "Nashik")]
    res <- getWilcoxonTest(
        tse_two,
        counts ~ Geographical_location,
        effect_size = "cliff"
    )
    expect_s3_class(res, "data.frame")
    expect_true(all(c(
        "effect_size",
        "effect_size_lower",
        "effect_size_upper",
        "effect_size_magnitude"
    ) %in% names(res)))
})

test_that("getWilcoxonTest adds Cohen's d for unpaired two-group comparisons", {
    tse_two <- tse[, tse$Geographical_location %in% c("Ahmednagar", "Nashik")]
    res <- getWilcoxonTest(
        tse_two,
        counts ~ Geographical_location,
        effect_size = "cohen"
    )
    expect_s3_class(res, "data.frame")
    expect_true(all(c(
        "effect_size",
        "effect_size_magnitude"
    ) %in% names(res)))
})

test_that("getWilcoxonTest does not add Cliff's delta for paired tests", {
    tse_two <- tse[, tse$Geographical_location %in% c("Ahmednagar", "Nashik")]
    tse_two$pair_id <- seq_len(ncol(tse_two))

    res <- getWilcoxonTest(
        tse_two,
        counts ~ Geographical_location,
        pair.by = "pair_id",
        effect_size = "cliff"
    )

    expect_s3_class(res, "data.frame")
    expect_false("effect_size" %in% names(res))
})
