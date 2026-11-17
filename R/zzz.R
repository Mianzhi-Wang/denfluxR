# Global variable to hold the Python denflux module reference
denflux <- NULL

.onLoad <- function(libname, pkgname) {
  # Use delay_load = TRUE to defer Python initialization until the user actually calls a function.
  denflux <<- reticulate::import("denflux", delay_load = TRUE)
}

#' Install the Python denflux package
#'
#' @description
#' A helper function to automatically install the underlying Python package denflux.
#' If your system Python is not found automatically (e.g., Anaconda not in PATH),
#' you can explicitly provide the path to your Python executable.
#'
#' @param python_path Character. Optional. The explicit path to your Python executable
#' (e.g., "C:/path/to/anaconda3/python.exe"). If NULL, reticulate will try to find one automatically.
#'
#' @export
install_denflux <- function(python_path = NULL) {
  envname <- "denflux-env"

  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required but not installed.")
  }

  message("Preparing Python environment...")

  # If the user explicitly provided a path, tell reticulate to use it.
  # This cleanly solves the "hidden Anaconda" issue without messing with global variables.
  if (!is.null(python_path)) {
    if (!file.exists(python_path)) {
      stop("The provided python_path does not exist: ", python_path)
    }
    message("Using user-provided Python: ", python_path)
    reticulate::use_python(python_path, required = TRUE)
  } else {
    # Check if we can find ANY python automatically.
    if (!reticulate::py_available(initialize = FALSE)) {
      stop(
        "No Python installation was found automatically on your system.\n",
        "If you have Conda or Python installed, they might not be in your system PATH.\n",
        "Please run this function again providing your exact Python path, for example:\n",
        "  install_denflux(python_path = 'C:/path/to/anaconda3/python.exe')\n",
        "Or install Python manually from https://www.python.org/downloads/."
      )
    }
  }

  message(sprintf("Configuring dedicated virtual environment '%s'...", envname))
  tryCatch({
    # We use method = "virtualenv" explicitly here.
    # If the user provided a Conda python_path, virtualenv will cleanly wrap around it
    # without triggering Conda's Terms of Service errors.
    reticulate::py_install(
      packages = "denflux",
      envname = envname,
      method = "virtualenv"
    )
  }, error = function(e) {
    stop("Failed to configure Python backend. Error: ", e$message)
  })

  # Lock this session to the newly created environment
  reticulate::use_virtualenv(envname, required = TRUE)

  message("Successfully installed the DenFlux backend.")
  message("You are ready to use process()!")
}
