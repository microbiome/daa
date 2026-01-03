
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

## Contributing

Contributions are welcome in the form of feedback, issues, and pull
requests. See [contributor guidelines](CONTRIBUTING.md).

## Code of Conduct

Please note that the daa project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
