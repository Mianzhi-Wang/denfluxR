
<!-- README.md is generated from README.Rmd. Please edit that file -->

# denfluxR

<!-- badges: start -->

[![R
Version](https://img.shields.io/badge/R-4.0+-blue.svg)](https://cran.r-project.org/)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Powered by
DenFlux](https://img.shields.io/badge/Powered%20by-DenFlux%20(PyPI)-orange.svg)](https://pypi.org/project/denflux/)
<!-- badges: end -->

`denfluxR` is the R interface for the [DenFlux Python
engine](https://github.com/Mianzhi-Wang/DenFlux) (also available on
[PyPI](https://pypi.org/project/denflux/)). It provides a process-based
computational framework to dynamically reconstruct the corrected
zero-flow baseline for Granier thermal dissipation probes using machine
learning (Random Forest) and physiological constraints.

## Installation

You can install the development version of `denfluxR` from
[GitHub](https://github.com/Mianzhi-Wang/denfluxR) with:

``` r
# install.packages("devtools")
devtools::install_github("Mianzhi-Wang/denfluxR")
```

### Python Backend Setup

`denfluxR` relies on the `denflux` Python package. Once you have
installed `denfluxR` in R, you must configure the backend engine by
running:

``` r
library(denfluxR)
install_denflux()
```

*This will automatically create an isolated Conda/Virtual environment
and install the required Python dependencies via `reticulate`.*

## Basic Usage

Here is a quick example of how to process your sap flow data:

``` r
library(denfluxR)

# Assuming you have a dataframe named 'my_data'
# result <- process(
#   data = my_data,
#   time_col = "Time",
#   dayfirst = TRUE,
#   Radiation = "PAR",
#   night_threshold = 10,
#   growstart = 5,
#   growend = 9
# )
# head(result)
```

For more detailed information and visualization examples, please refer
to the package vignette.

## Citation

If you use `denfluxR` or the underlying `DenFlux` engine in your
research, please cite our manuscript. A permanent DOI will be updated
upon publication.

> **\[Wang M\], et al. (In Review).** *\[Paper Title\]*. Submitted to
> \[Journal Name\].

\`\`\`bibtex @article{denflux_under_review, title={\[Paper Title\]},
author={\[Author 1 and Author 2 and Author 3\]}, journal={Submitted to
\[Journal Name\]}, year={2026}, note={Under Review} }
