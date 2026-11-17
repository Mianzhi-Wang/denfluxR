# Global variable to hold the Python denflux module reference
denflux <- NULL

.onLoad <- function(libname, pkgname) {
  # Use delay_load = TRUE to defer Python initialization until the user actually calls a function.
  # This significantly improves package loading stability and prevents immediate crashes if Python is not configured.
  denflux <<- reticulate::import("denflux", delay_load = TRUE)
}

#' Install the Python denflux package
#'
#' @description
#' A helper function to automatically install the underlying Python package `denflux`
#' via pip into the R-reticulate environment.
#'
#' @param envname The name of the Python environment. Default is "r-reticulate".
#' @param method Installation method. Default is "auto".
#' @param ... Additional arguments passed to \code{reticulate::py_install}.
#' @export
install_denflux <- function(method = "auto", conda = "auto", pip_options = "") {
  message("Attempting to install Python package 'denflux' from PyPI...")

  reticulate::py_install(
    packages = "denflux",
    envname = "r-reticulate",
    method = method,
    conda = conda,
    pip = TRUE,
    pip_options = pip_options
  )
  message("Installation complete. Please restart your R session.")
}

