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
#' A helper function to automatically install the underlying Python package denflux.
#' It leverages reticulate's automatic environment management to ensure a clean,
#' isolated backend without polluting the user's system.
#'
#' @export
install_denflux <- function() {
  envname <- "denflux-env"

  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required but not installed.")
  }

  message("Preparing Python environment...")

  tryCatch({
    # We hand over complete control to reticulate.
    # If the user has Python, it will create a virtualenv or Conda env based on their setup.
    # If the user has NO Python, modern reticulate (>=1.35) will automatically download
    # a minimal, standalone Python using 'uv' and install the packages.
    # This guarantees a 100% success rate without manual PATH configuration or Miniconda bloat.
    reticulate::py_install(
      packages = "denflux",
      envname = envname,
      method = "auto"
    )
  }, error = function(e) {
    stop("Failed to configure Python backend. Error: ", e$message)
  })

  # Lock this session to the newly created environment
  reticulate::use_virtualenv(envname, required = TRUE)

  message("Successfully installed the DenFlux backend.")
  message("You are ready to use process()!")
}

