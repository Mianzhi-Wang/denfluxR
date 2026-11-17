#' Process Sapflow Data using DenFlux Baseline Correction
#'
#' @description
#' This function acts as an R wrapper for the underlying Python `denflux` engine.
#' It provides a process-based computational framework to dynamically reconstruct
#' the corrected zero-flow baseline for Granier thermal dissipation probes using
#' machine learning (Random Forest) and physiological constraints.
#'
#' @param data A data.frame containing timestamps and required environmental/sap flow variables.
#' @param time_col Character, default 'Time'. The name of the column containing timestamps.
#' @param dayfirst Logical, default FALSE. Set to TRUE if dates are formatted as DD/MM/YYYY.
#' @param date_format Character, default NULL. Explicit datetime format string (e.g., '%Y-%m-%d %H:%M:%S').
#' @param time_interval Numeric, default 5. The temporal resolution of the raw data in minutes.
#' @param alpha Numeric, default 0.0119. Calibration parameter alpha for the Granier formula.
#' @param beta Numeric, default 1.231. Calibration parameter beta for the Granier formula.
#' @param growstart Integer, default 5. The starting month of the growing season (1-12).
#' @param growend Integer, default 9. The ending month of the growing season (1-12).
#' @param apply_rolling Logical, default TRUE. Whether to apply a rolling average to smooth data.
#' @param rolling_window Numeric, default 30. The window size for the rolling average in minutes.
#' @param night_threshold Numeric, default 10. Radiation value below which it is mathematically considered "nighttime".
#' @param Radiation Character, default 'PAR'. Column name for solar radiation.
#' @param daycheck_start Integer, default 10. Start hour (0-23) for daytime leakage checking.
#' @param daycheck_end Integer, default 16. End hour (0-23) for daytime leakage checking.
#' @param deci_tree_T Integer, default 200. Number of trees in the forest for Transpiration model.
#' @param depth_T Integer, default 12. Maximum depth of the Transpiration regression estimators.
#' @param min_leaf_T Integer, default 5. Minimum number of samples required at a leaf node (Transpiration).
#' @param max_fea_T Character, default 'sqrt'. Number of features to consider when looking for the best split (Transpiration).
#' @param random_state_T Integer, default 42. Seed for the random number generator (Transpiration).
#' @param deci_tree_R Integer, default 200. Number of trees in the forest for Rehydration model.
#' @param depth_R Integer, default 12. Maximum depth of the Rehydration regression estimators.
#' @param min_leaf_R Integer, default 5. Minimum number of samples required at a leaf node (Rehydration).
#' @param max_fea_R Character, default 'sqrt'. Number of features to consider when looking for the best split (Rehydration).
#' @param random_state_R Integer, default 42. Seed for the random number generator (Rehydration).
#' @param expected_r2 Numeric, default 0.3. Validation R-squared threshold. Triggers a warning if models perform below this.
#' @param diagnostic_plots Logical, default FALSE. If TRUE, displays matplotlib figures for ML performance.
#'
#' @return A data.frame with the original data plus the calculated baseline and sap flux density.
#' @export
#'
#' @examples
#' \dontrun{
#' # Assuming 'my_data' is a loaded data.frame with 5-min resolution
#' result <- process(
#'   data = my_data,
#'   time_col = "Timestamp",
#'   Radiation = "PAR",
#'   growstart=5,
#'   growend=9,
#'   night_threshold=10
#' )
#' head(result)
#' }
process <- function(data,
                    time_col = 'Time',
                    dayfirst = FALSE,
                    date_format = NULL,
                    alpha = 0.0119,
                    beta = 1.231,
                    growstart = 5,
                    growend = 9,
                    time_interval = 5,
                    apply_rolling = TRUE,
                    rolling_window = 30,
                    night_threshold = 10,
                    Radiation = "PAR",
                    daycheck_start = 10,
                    daycheck_end = 16,
                    deci_tree_T = 200,
                    depth_T = 12,
                    min_leaf_T = 5,
                    max_fea_T = 'sqrt',
                    random_state_T = 42,
                    deci_tree_R = 200,
                    depth_R = 12,
                    min_leaf_R = 5,
                    max_fea_R = 'sqrt',
                    random_state_R = 42,
                    expected_r2 = 0.3,
                    diagnostic_plots = FALSE) {

  # 1. Verify Python environment
  if (is.null(denflux)) {
    stop("Python module 'denflux' is not loaded. Please run denfluxR::install_denflux() if you haven't installed it.")
  }

  # ---------------------------------------------------------
  # NEW: Check for Python engine updates silently (Once per session)
  # ---------------------------------------------------------
  if (is.null(getOption("denflux_version_checked"))) {
    tryCatch({
      # 1. Get the local installed version using Python's importlib
      local_ver <- reticulate::py_eval("import importlib.metadata as meta; meta.version('denflux')")

      # 2. Quietly fetch the latest version from PyPI's JSON API
      con <- url("https://pypi.org/pypi/denflux/json")
      pypi_data <- readLines(con, warn = FALSE)
      close(con)

      # Extract version string using a simple regular expression (avoids extra package dependencies)
      latest_ver <- sub('.*"version":"([^"]+)".*', '\\1', paste(pypi_data, collapse=""))

      # 3. Compare standard semantic versions (e.g., 0.1.1 vs 0.1.2)
      if (package_version(local_ver) < package_version(latest_ver)) {
        warning(
          sprintf(
            "A newer version of the Python 'denflux' engine is available on PyPI!\nYour version: %s | Latest version: %s\nPlease run `denfluxR::install_denflux(method = 'auto', pip_options = '--upgrade')` to update.",
            local_ver, latest_ver
          ),
          call. = FALSE, immediate. = TRUE
        )
      }
      # Set the lock so we don't bother PyPI or the user again in this R session
      options(denflux_version_checked = TRUE)

    }, error = function(e) {
      # If the user is offline or the check fails, just silently skip and set the lock
      options(denflux_version_checked = TRUE)
    })
  }
  # ---------------------------------------------------------

  # 2. Check if the time column and Radiation column exist in the R data.frame
  if (!(time_col %in% names(data))) {
    stop(paste("The specified time_col", time_col, "does not exist in your dataframe."))
  }
  if (!(Radiation %in% names(data))) {
    stop(paste("The specified Radiation column", Radiation, "does not exist in your dataframe."))
  }

  # 3. Format datetime correctly for Pandas
  df_to_python <- data
  if (inherits(df_to_python[[time_col]], "POSIXt") || inherits(df_to_python[[time_col]], "Date")) {
    df_to_python[[time_col]] <- as.character(df_to_python[[time_col]])
  }

  message("Running DenFlux baseline correction engine...")

  # 4. Pass ALL arguments cleanly to the Python backend
  tryCatch({
    # mute redundant warning
    reticulate::py_run_string("import warnings; warnings.filterwarnings('ignore')")

    # Explicitly import core modules
    py_core <- reticulate::import("denflux.core", delay_load = TRUE)

    # Call the Python process function using the imported module
    result_py <- py_core$process(
      df = df_to_python,
      time_col = as.character(time_col),
      dayfirst = as.logical(dayfirst),
      date_format = date_format, # NULL in R translates naturally to None in Python
      alpha = as.numeric(alpha),
      beta = as.numeric(beta),
      growstart = as.integer(growstart),
      growend = as.integer(growend),
      time_interval = as.numeric(time_interval),
      apply_rolling = as.logical(apply_rolling),
      rolling_window = as.numeric(rolling_window),
      night_threshold = as.numeric(night_threshold),
      Radiation = as.character(Radiation),
      daycheck_start = as.integer(daycheck_start),
      daycheck_end = as.integer(daycheck_end),
      deci_tree_T = as.integer(deci_tree_T),
      depth_T = as.integer(depth_T),
      min_leaf_T = as.integer(min_leaf_T),
      max_fea_T = as.character(max_fea_T),
      random_state_T = as.integer(random_state_T),
      deci_tree_R = as.integer(deci_tree_R),
      depth_R = as.integer(depth_R),
      min_leaf_R = as.integer(min_leaf_R),
      max_fea_R = as.character(max_fea_R),
      random_state_R = as.integer(random_state_R),
      expected_r2 = as.numeric(expected_r2),
      diagnostic_plots = as.logical(diagnostic_plots)
    )

    # Restore Python's warning mechanism
    reticulate::py_run_string("warnings.resetwarnings()")

    # 5. Convert results back to R format
    # Force cross-language data frame conversion using as.data.frame
    result_r <- as.data.frame(result_py)

    # Reconstruct DateTime Index into a column if pandas returned it as an index
    if ("Time" %in% names(result_r) && inherits(result_r$Time, "character")) {
      result_r$Time <- as.POSIXct(result_r$Time, tz = "UTC")
    }

    return(result_r)

  }, error = function(e) {
    # Ensure that warning settings can be restored when an error occurs.
    reticulate::py_run_string("import warnings; warnings.resetwarnings()")
    stop(paste("An error occurred in the Python engine:\n", e$message))
  })
}
