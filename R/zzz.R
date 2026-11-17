# Global variable to hold the Python denflux module reference
denflux <- NULL

.onLoad <- function(libname, pkgname) {
  # Use delay_load = TRUE to defer Python initialization until the user actually calls a function.
  # This significantly improves package loading stability and prevents immediate crashes.
  denflux <<- reticulate::import("denflux", delay_load = TRUE)
}

#' Install the Python denflux package
#'
#' @description
#' A helper function to automatically install the underlying Python package denflux
#' into a dedicated, isolated Python environment. It handles the environment setup
#' silently, ensuring no conflicts with existing user installations.
#'
#' @export
install_denflux <- function() {
  envname <- "denflux-env"

  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required but not installed.")
  }

  message("Preparing Python environment...")

  # Defense: If no Python is found on the system, gracefully install a minimal Miniconda.
  # This prevents permission errors on Windows systems without a registered Python.
  if (!reticulate::py_available(initialize = FALSE)) {
    message("No suitable Python found. Installing a lightweight Miniconda distribution in the background...")
    tryCatch({
      reticulate::install_miniconda()
    }, error = function(e) {
      warning("Could not install Miniconda automatically. Please install Python manually from https://www.python.org/downloads/ and try again.")
    })
  }

  # Configure the environment using reticulate's smart auto-method
  message(sprintf("Configuring dedicated virtual environment '%s'...", envname))
  tryCatch({
    reticulate::py_install(
      packages = "denflux",
      envname = envname,
      method = "auto"
    )
  }, error = function(e) {
    stop("Failed to configure Python backend. Error: ", e$message)
  })

  # Force R to lock onto this newly configured environment
  reticulate::use_virtualenv(envname, required = TRUE)

  message("Successfully installed the DenFlux backend.")
  message("You are ready to use process()!")
}

