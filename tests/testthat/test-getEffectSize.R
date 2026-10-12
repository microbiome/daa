# Tests for getEffectSize
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")

test_that("getEffectSize matches effsize for each feature and pair", {
    res <- getEffectSize(tse, counts ~ Geographical_location)
    row <- res[res$rownames == "Firmicutes" &
        res$group1 == "Ahmednagar" & res$group2 == "Pune", ]

    keep <- tse$Geographical_location %in% c("Ahmednagar", "Pune")
    expected <- effsize::cliff.delta(
        SummarizedExperiment::assay(tse, "counts")["Firmicutes", keep],
        factor(tse$Geographical_location[keep],
            levels = c("Ahmednagar", "Pune"))
    )

    expect_equal(row$effsize, unname(expected$estimate))
    expect_equal(c(row$conf.low, row$conf.high), unname(expected$conf.int))
    expect_equal(row$magnitude, as.character(expected$magnitude))
})

test_that("getEffectSize calculates Cohen's d", {
    res <- getEffectSize(tse, counts ~ Gender, method = "cohen")
    row <- res[res$rownames == "Firmicutes", ]

    expected <- effsize::cohen.d(
        SummarizedExperiment::assay(tse, "counts")["Firmicutes", ],
        factor(tse$Gender, levels = c(row$group1, row$group2))
    )

    expect_equal(row$effsize, unname(expected$estimate))
})

test_that("getEffectSize returns every feature and pair of groups", {
    res <- getEffectSize(tse, counts ~ Geographical_location)

    expect_identical(
        colnames(res),
        c("rownames", "group1", "group2", "effsize", "conf.low",
            "conf.high", "magnitude")
    )
    expect_equal(nrow(res), nrow(tse) * 3L)
})

test_that("getEffectSize requires one grouping variable", {
    expect_error(
        getEffectSize(tse, counts ~ Gender + Diet),
        "exactly one grouping variable"
    )
})
