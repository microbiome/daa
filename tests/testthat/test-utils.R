# Tests for utils.R functions

# Use HintikkaXOData for reliable tests
# Need getWithColData to get colData from MAE
data(HintikkaXOData, package = "mia")
mae <- HintikkaXOData
tse <- MultiAssayExperiment::getWithColData(mae, "microbiota")
tse <- mia::transformAssay(tse, method = "relabundance")
tse <- tse[1:10, ]

################################################################################
# .check_input tests
################################################################################

test_that(".check_input requires exactly one data source", {
    expect_error(
        .check_input(tse, NULL, NULL, NULL, ~Fat, NULL, NULL, NULL),
        "either"
    )
    expect_error(
        .check_input(
            tse, "relabundance", "var", NULL, ~Fat,
            NULL, NULL, NULL
        ),
        "either"
    )
})

test_that(".check_input validates features only with assay.type", {
    expect_error(
        .check_input(tse, NULL, NULL, "Fat", ~Fat, NULL, NULL,
            features = "Taxa1"
        ),
        "features"
    )
})

test_that(".check_input validates features exist", {
    expect_error(
        .check_input(tse, "relabundance", NULL, NULL, ~Fat, NULL, NULL,
            features = c("nonexistent")
        ),
        "features"
    )
})

test_that(".check_input validates formula", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, "not a formula",
            NULL, NULL, NULL
        ),
        "must be a formula"
    )
})

test_that(".check_input validates formula variable exists", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, ~nonexistent,
            NULL, NULL, NULL
        ),
        "not found"
    )
})

test_that(".check_input validates split.by exists", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, ~Fat,
            "nonexistent", NULL, NULL
        ),
        "not found"
    )
})

test_that(".check_input validates pair.by exists", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, ~Fat, NULL,
            "nonexistent", NULL
        ),
        "not found"
    )
})

test_that(".check_input passes with valid inputs", {
    expect_silent(
        .check_input(
            tse, "relabundance", NULL, NULL, ~Fat,
            NULL, NULL, NULL
        )
    )
})

################################################################################
# .get_rhs_var tests
################################################################################

test_that(".get_rhs_var extracts group from formula", {
    result <- .get_rhs_var(~Fat)
    expect_equal(result, "Fat")
})

test_that(".get_rhs_var fails with non-formula", {
    expect_error(.get_rhs_var("not a formula"), "must be a formula")
})

################################################################################
# .check_group tests
################################################################################

test_that(".check_group validates at least 2 levels", {
    df <- data.frame(group = c("A"), value = 1)
    expect_error(.check_group(df, "group"), "at least 2 levels")
})

test_that(".check_group passes with valid 2-level group", {
    df <- data.frame(group = c("A", "B"), value = 1:2)
    expect_silent(.check_group(df, "group"))
})

################################################################################
# .get_data tests
################################################################################

test_that(".get_data with assay.type returns correct format", {
    df <- .get_data(
        tse, "relabundance", NULL, NULL, "Fat",
        NULL, NULL, NULL
    )

    expect_s3_class(df, "data.frame")
    expect_true("relabundance" %in% names(df))
    expect_true("Fat" %in% names(df))
    expect_true("FeatureID" %in% names(df))
})

test_that(".get_data with col.var returns correct format", {
    tse_alpha <- mia::addAlpha(tse, index = "shannon_diversity")
    df <- .get_data(
        tse_alpha, NULL, NULL, "shannon_diversity",
        "Fat", NULL, NULL, NULL
    )

    expect_s3_class(df, "data.frame")
    expect_true("shannon_diversity" %in% names(df))
    expect_true("Fat" %in% names(df))
})
