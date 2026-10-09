#' @title One index series from a table of survey indices
#' @description Picks one index out of a long table of survey indices and
#'   returns it in the form the rules take (columns `year` and `index`).
#'
#' @param survey_index A data frame of survey indices with a column `index`
#'   naming the series, a column `year` and the value column.
#' @param name The name of the series (value of the `index` column).
#' @param year_end Last year to keep (e.g. the assessment year), or NULL for
#'   all years.
#' @param value Name of the value column (`"b"` for biomass, `"n"` for
#'   abundance).
#'
#' @return A tibble with the columns `year` and `index`.
#' @export
index_series <- function(survey_index, name, year_end = NULL, value = "b") {
  out <- survey_index[survey_index$index == name, , drop = FALSE]
  if (!is.null(year_end)) {
    out <- out[out$year <= year_end, , drop = FALSE]
  }
  tibble::tibble(year = out$year, index = out[[value]])
}

#' @title I_loss from an index series
#' @description I_loss, the index value below which the stock is considered
#'   to deteriorate, from the biomass index of the rule. ICES (2025) defines
#'   it as the lowest observed index value, but stocks differ, and the
#'   choice changes I_trigger and the biomass safeguard, so the method has no
#'   default:
#'
#'   * `"min"`: the lowest index value.
#'   * `"second_min"`: the second lowest index value.
#'   * `"mean"`: the mean of the index in `years` (all of them must be in the
#'     index).
#'   * `"fixed"`: `value`.
#'
#'   Missing index values are ignored.
#'
#' @param index A data frame with the columns `year` and `index`, cut at the
#'   assessment year (see [index_series()]).
#' @param method One of `"min"`, `"second_min"`, `"mean"` or `"fixed"`.
#' @param years The years of the mean (method `"mean"`).
#' @param value The value (method `"fixed"`).
#'
#' @return A list with `I_loss` and `year`, the year of the index value used
#'   (NULL for the methods `"mean"` and `"fixed"`).
#' @export
calc_iloss <- function(index, method, years = NULL, value = NULL) {
  method <- match.arg(method, c("min", "second_min", "mean", "fixed"))
  if (method == "fixed") {
    if (!is.numeric(value) || length(value) != 1) {
      stop("method = \"fixed\" needs a single numeric value")
    }
    return(list(I_loss = value, year = NULL))
  }
  if (!all(c("year", "index") %in% names(index))) {
    stop("The index must have the columns 'year' and 'index'")
  }
  index <- index[!is.na(index$index), , drop = FALSE]
  switch(
    method,
    min = {
      i <- which.min(index$index)
      list(I_loss = min(index$index), year = index$year[i])
    },
    second_min = {
      if (nrow(index) < 2) {
        stop("method = \"second_min\" needs at least two index values")
      }
      i <- order(index$index)[2]
      list(I_loss = index$index[i], year = index$year[i])
    },
    mean = {
      if (is.null(years)) {
        stop("method = \"mean\" needs the years of the mean")
      }
      index <- index[index$year %in% years, , drop = FALSE]
      if (!all(years %in% index$year)) {
        stop(
          "The index has no value in ",
          paste(setdiff(years, index$year), collapse = ", ")
        )
      }
      list(I_loss = mean(index$index), year = NULL)
    }
  )
}

#' @title Add I_loss and I_trigger to the reference points
#' @description Sets `I_lim` (= I_loss, see [calc_iloss()]), `I_lim_year`
#'   (for the methods that pick one year) and `I_trigger` = `itrigger_factor`
#'   x I_loss in a list of reference points, as [rfb_rule()] and the history
#'   and report tables use them.
#'
#' @param ref_points A list of reference points (e.g. `K`, `Linf`, `Lc`).
#' @inheritParams calc_iloss
#' @param itrigger_factor I_trigger / I_loss (1.4 in ICES 2025).
#'
#' @return `ref_points` with the elements `I_lim`, (`I_lim_year`,) and
#'   `I_trigger` set.
#' @export
ref_points_iloss <- function(
  ref_points,
  index,
  method,
  years = NULL,
  value = NULL,
  itrigger_factor = 1.4
) {
  iloss <- calc_iloss(index, method = method, years = years, value = value)
  ref_points$I_lim <- iloss$I_loss
  if (!is.null(iloss$year)) {
    ref_points$I_lim_year <- iloss$year
  }
  ref_points$I_trigger <- calc_Itrigger(ref_points$I_lim, factor = itrigger_factor)
  ref_points
}
