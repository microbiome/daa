# Tests for utils.R functions

# Use GlobalPatterns for reliable tests
data(GlobalPatterns, package = "mia")
tse <- GlobalPatterns
tse <- mia::transformAssay(tse, method = "relabundance")
tse <- tse[1:10, tse$SampleType %in% c("Feces", "Skin")]
tse$numeric_col <- as.numeric(seq_len(ncol(tse)))

################################################################################
# .check_input tests
################################################################################

test_that(".check_input requires exactly one data source", {
    expect_error(
        .check_input(tse, NULL, NULL, NULL, ~SampleType, NULL, NULL, NULL),
        "either"
    )
    expect_error(
        .check_input(
            tse, "relabundance", "var", NULL, ~SampleType,
            NULL, NULL, NULL
        ),
        "either"
    )
})

test_that(".check_input validates features only with assay.type", {
    expect_error(
        .check_input(tse, NULL, NULL, "SampleType", ~SampleType, NULL, NULL,
            features = "Taxa1"
        ),
        "features"
    )
})

test_that(".check_input validates features exist", {
    expect_error(
        .check_input(tse, "relabundance", NULL, NULL, ~SampleType, NULL, NULL,
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
        "must be a single character value from the following options"
    )
})

test_that(".check_input validates split.by exists", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, ~SampleType,
            "nonexistent", NULL, NULL
        ),
        "must be a single character value from the following options"
    )
})

test_that(".check_input validates pair.by exists", {
    expect_error(
        .check_input(
            tse, "relabundance", NULL, NULL, ~SampleType, NULL,
            "nonexistent", NULL
        ),
        "must be a single character value from the following options"
    )
})

test_that(".check_input passes with valid inputs", {
    expect_silent(
        .check_input(
            tse, "relabundance", NULL, NULL, ~SampleType,
            NULL, NULL, NULL
        )
    )
})

################################################################################
# .get_rhs_var tests
################################################################################

test_that(".get_rhs_var extracts group from formula", {
    result <- .get_rhs_var(~SampleType)
    expect_equal(result, "SampleType")
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
        tse, "relabundance", NULL, NULL, "SampleType",
        NULL, NULL, NULL
    )

    expect_s3_class(df, "data.frame")
    expect_true("relabundance" %in% names(df))
    expect_true("SampleType" %in% names(df))
    expect_true("FeatureID" %in% names(df))
})

test_that(".get_data with col.var returns correct format", {
    df <- .get_data(
        tse, NULL, NULL, "numeric_col",
        "SampleType", NULL, NULL, NULL
    )

    expect_s3_class(df, "data.frame")
    expect_true("numeric_col" %in% names(df))
    expect_true("SampleType" %in% names(df))
})
