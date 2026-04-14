# Tests for getAnova
data(peerj13075, package = "mia")
tse <- peerj13075
tse <- mia::agglomerateByRank(tse, "phylum")

test_that("getAnova with assay works", {
    res <- getAnova(tse, counts ~ Geographical_location) |>
        as.data.frame() |>
        dplyr::arrange(.data[["rownames"]])

    mat <- SummarizedExperiment::assay(tse, "counts") |>
        as.data.frame()
    mat[["rownames"]] <- rownames(mat)
    sample_metadata <- as.data.frame(SummarizedExperiment::colData(tse))
    sample_metadata[["sample_id"]] <- rownames(sample_metadata)

    manual_df <- tidyr::pivot_longer(
        mat,
        cols = -"rownames",
        names_to = "sample_id",
        values_to = "counts"
    ) |>
        dplyr::left_join(sample_metadata, by = "sample_id") |>
        dplyr::group_by(.data[["rownames"]], .data[["Geographical_location"]]) |>
        dplyr::filter(
            dplyr::n_distinct(.data[["counts"]]) > 1,
            stats::var(.data[["counts"]], na.rm = TRUE) > 0
        ) |>
        dplyr::ungroup() |>
        dplyr::group_by(.data[["rownames"]]) |>
        dplyr::filter(
            dplyr::n_distinct(.data[["Geographical_location"]]) >= 2
        ) |>
        dplyr::ungroup()

    manual_res <- lapply(split(manual_df, manual_df$rownames), function(df) {
        out <- rstatix::anova_test(df, counts ~ Geographical_location)
        class(out) <- "data.frame"
        out
    })
    names(manual_res) <- names(split(manual_df, manual_df$rownames))

    manual_res <- dplyr::bind_rows(manual_res, .id = "rownames") |>
        as.data.frame() |>
        dplyr::arrange(.data[["rownames"]])

    expect_s3_class(res, "data.frame")
    expect_equal(res$rownames, manual_res$rownames)
    expect_equal(res$Effect, manual_res$Effect)
    expect_equal(res$DFn, manual_res$DFn)
    expect_equal(res$DFd, manual_res$DFd)
    expect_equal(res$F, manual_res$F)
    expect_equal(res$p, manual_res$p)
    expect_equal(res$ges, manual_res$ges)
})
