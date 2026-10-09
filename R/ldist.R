#' @title Catch length distributions for the rule
#' @description Length distributions of the catch by year and 1 cm length
#'   (optionally also by gear) from a pax database, for the length-based
#'   components of the rfb and chr rules (mean length above L_c, the
#'   fishing pressure proxy and the harvest rate proxy).
#'
#'   The `ldist` table of a pax database built by `pax::pax_from_mar()` is
#'   already raised to the counted fish, so the lengths are only rounded
#'   here (`pax::pax_ldist_scale_round()`); the counts are not raised a
#'   second time.
#'
#'   The query runs in the database and only the summed result is collected.
#'   pax is only needed by this function (it is in Suggests); all other
#'   functions of the package take plain data frames.
#'
#' @param station A `tbl` of the pax `station` table (e.g.
#'   `dplyr::tbl(pcon, "station")`, or a stock-specific accessor that fills
#'   in gear codes).
#' @param ldist A `tbl` of the pax `ldist` table, unrounded (e.g.
#'   `dplyr::tbl(pcon, "ldist")`).
#' @param gears mfdb gear codes to keep, or NULL for all gears.
#' @param year_start First year to keep, or NULL for all years.
#' @param sampling_type Sampling types of the stations (1, 2 and 8 are the
#'   commercial samples at sea and in port).
#' @param by_gear If TRUE, keep the gear (`mfdb_gear_code`) as a column.
#'
#' @return A tibble with the columns `year`, (`mfdb_gear_code`,) `length` and
#'   `n` (numbers), sorted by these columns. Samples without the species (no
#'   length) are dropped.
#' @export
catch_ldist <- function(
  station,
  ldist,
  gears = NULL,
  year_start = NULL,
  sampling_type = c(1, 2, 8),
  by_gear = FALSE
) {
  if (!requireNamespace("pax", quietly = TRUE)) {
    stop("catch_ldist() needs the pax package (hafro/pax on GitHub)")
  }
  # NSE variables
  year <- mfdb_gear_code <- n <- NULL

  st_type <- sampling_type
  station <- dplyr::filter(station, sampling_type %in% local(st_type))
  if (!is.null(year_start)) {
    station <- dplyr::filter(station, year >= local(year_start))
  }
  out <- station |>
    pax::pax_ldist_by_year(ldist_tbl = pax::pax_ldist_scale_round(ldist)) |>
    # Samples without the species have no length
    dplyr::filter(!is.na(length))
  if (!is.null(gears)) {
    out <- dplyr::filter(out, mfdb_gear_code %in% local(gears))
  }
  if (by_gear) {
    out |>
      dplyr::group_by(year, mfdb_gear_code, length) |>
      dplyr::summarise(n = sum(n, na.rm = TRUE), .groups = "drop") |>
      dplyr::collect() |>
      dplyr::ungroup() |>
      dplyr::arrange(year, mfdb_gear_code, length)
  } else {
    out |>
      dplyr::group_by(year, length) |>
      dplyr::summarise(n = sum(n, na.rm = TRUE), .groups = "drop") |>
      dplyr::collect() |>
      dplyr::ungroup() |>
      dplyr::arrange(year, length)
  }
}

#' @title Length distributions of the rule from a collected table
#' @description Selects the gears, years and lengths of the rule from a
#'   length distribution by year, gear and length (such as
#'   `catch_ldist(by_gear = TRUE)`), sums it by year and length, and
#'   optionally adds other length distributions (e.g. survey lengths in years
#'   without catch samples).
#'
#' @param ldist A data frame with the columns `year`, `length` and `n`, and
#'   `mfdb_gear_code` if `gears` is given.
#' @param gears mfdb gear codes to keep, or NULL for all.
#' @param year_start First year to keep, or NULL for all.
#' @param max_length Keep lengths strictly below this, or NULL for all (e.g.
#'   to drop a mis-entered length).
#' @param extra NULL, or a data frame with the columns `year`, `length` and
#'   `n` that is added to the selected distribution before the final sum.
#'
#' @return A tibble with the columns `year`, `length` and `n`, sorted by year
#'   and length.
#' @export
rule_ldist <- function(
  ldist,
  gears = NULL,
  year_start = NULL,
  max_length = NULL,
  extra = NULL
) {
  # NSE variables
  year <- mfdb_gear_code <- n <- NULL

  if (!is.null(gears)) {
    ldist <- dplyr::filter(ldist, mfdb_gear_code %in% gears)
  }
  if (!is.null(year_start)) {
    ldist <- dplyr::filter(ldist, year >= year_start)
  }
  if (!is.null(max_length)) {
    ldist <- dplyr::filter(ldist, length < max_length)
  }
  out <- ldist |>
    dplyr::group_by(year, length) |>
    dplyr::summarise(n = sum(n), .groups = "drop")
  if (!is.null(extra)) {
    out <- out |>
      dplyr::bind_rows(extra) |>
      dplyr::group_by(year, length) |>
      dplyr::summarise(n = sum(n), .groups = "drop")
  }
  dplyr::arrange(out, year, length)
}
