
<!-- README.md is generated from README.Rmd. Please edit that file -->

# daa - Differential Abundance Analysis

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Bioc-release](http://bioconductor.org/shields/build/release/bioc/daa.svg)](http://bioconductor.org/packages/release/bioc/html/daa.html)
[![Codecov test
coverage](https://codecov.io/gh/microbiome/daa/graph/badge.svg)](https://app.codecov.io/gh/microbiome/daa)
<!-- badges: end -->

## Using the package

This package provides functions for differential abundance analysis
(DAA) of microbiome data. It works with `TreeSummarizedExperiment` and
`SummarizedExperiment` objects from the miaverse ecosystem.

**Available methods:**

- `getWilcoxon()` / `addWilcoxon()` - Wilcoxon rank-sum test
- `getTtest()` / `addTtest()` - t-test (Welch’s or Student’s)

For more information, see the [function
reference](https://microbiome.github.io/daa/reference/index.html) and
the [Orchestrating Microbiome Analysis
(OMA)](https://microbiome.github.io/OMA) online book.

## Installation

### Bioc-release

``` r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}

BiocManager::install("daa")
```

### Bioc-devel

``` r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}

BiocManager::install(version = "devel")
BiocManager::install("daa")
```

## Example

``` r
library(daa)
library(mia)

# Load example data (HintikkaXOData is used in unit tests)
data(HintikkaXOData, package = "mia")
tse <- MultiAssayExperiment::getWithColData(HintikkaXOData, "microbiota")
#> Warning: 'experiments' dropped; see 'drops()'

# Standardize assay data
tse <- transformAssay(tse, method = "relabundance")

# Subset to first 50 features for demonstration
tse <- tse[1:50, ]

# Run Wilcoxon test comparing groups in 'Fat' metadata column
res <- getWilcoxon(tse, assay.type = "relabundance", formula = ~Fat)
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
#> Warning: Statistical test failed for a feature: missing value where TRUE/FALSE
#> needed
head(res)
#> DataFrame with 6 rows and 10 columns
#>            .y.      group1      group2        n1        n2 statistic         p
#>    <character> <character> <character> <integer> <integer> <numeric> <numeric>
#> 1 relabundance         Low        High        20        20     262.0    0.0965
#> 2 relabundance         Low        High        20        20     228.0    0.2610
#> 3 relabundance         Low        High        20        20     210.0    0.3420
#> 4 relabundance         Low        High        20        20     210.0    0.3420
#> 5 relabundance         Low        High        20        20     200.5    1.0000
#> 6 relabundance         Low        High        20        20     190.0    0.3420
#>               FeatureID     warning     p.adj
#>                <factor> <character> <numeric>
#> 1 AATF01001055.137.1680          NA  0.435273
#> 2 AB506139.1.1558                NA  0.435273
#> 3 AB507689.1.1558                NA  0.435273
#> 4 AB559668.1.1567                NA  0.435273
#> 5 AB559692.1.1569                NA  1.000000
#> 6 AB559728.1.1569                NA  0.435273
```

## Contributing

Contributions are welcome in the form of feedback, issues, and pull
requests. See [contributor guidelines](CONTRIBUTING.md).

## Code of Conduct

Please note that the daa project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
