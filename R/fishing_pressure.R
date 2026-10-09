#' @title Mean length above the length at first capture
#' @description Mean length of the catch above L_c by year: the L_mean of the
#'   fishing pressure proxy of the rfb rule (ICES 2025, method 2.1) and of
#'   the harvest rate proxy of the chr rule (method 2.2).
#'
#' @param ldist A data frame with the columns `year`, `length` and `n`
#'   (e.g. from [catch_ldist()] or [rule_ldist()]).
#' @param Lc Length at first capture: lengths strictly above it are used.
#'
#' @return A tibble with the columns `year` and `mean_length`.
#' @export
mean_length_above <- function(ldist, Lc) {
  # NSE variables
  year <- n <- NULL

  ldist |>
    dplyr::filter(length > Lc) |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      mean_length = sum(length * n, na.rm = TRUE) / sum(n, na.rm = TRUE)
    )
}

#' @title Fishing pressure proxy by year
#' @description The f of the rfb rule, L_mean / L_F=M, and its inverse, the
#'   fishing pressure proxy L_F=M / L_mean that the assessment history shows
#'   as F (F_MSY proxy = 1), for each year with length data.
#'
#'   Which years enter the series differs between stocks and changes the
#'   history tables, so it is set by `year_start` and `year_end` rather than
#'   by a default: most stocks stop the series the year before the
#'   assessment year (`year_end = assessment_year - 1`), since the catch
#'   sampling of the assessment year is not complete at the time of the
#'   assessment.
#'
#' @inheritParams mean_length_above
#' @param Linf L_inf of the von Bertalanffy growth equation.
#' @param year_start,year_end First and last year of the series (inclusive).
#'
#' @return A tibble with the columns `year`, `mean_length` (L_mean above
#'   L_c), `f` (L_mean / L_F=M) and `F_proxy` (L_F=M / L_mean).
#' @seealso [target_reference_length()] for L_F=M.
#' @export
fproxy_series <- function(ldist, Lc, Linf, year_start = -Inf, year_end = Inf) {
  # NSE variables
  year <- mean_length <- NULL

  lfm <- target_reference_length(Lc = Lc, Linf = Linf)
  ldist |>
    dplyr::filter(year >= year_start, year <= year_end) |>
    mean_length_above(Lc = Lc) |>
    dplyr::mutate(f = mean_length / lfm, F_proxy = lfm / mean_length)
}

#' @title L_inf from the catch length distribution
#' @description A quantile of the individual lengths in the catch (all
#'   years), used as L_inf when the growth parameters are not reliable (the
#'   largest length when `p = 1`).
#'
#' @param ldist A data frame with the columns `length` and `n`; `n` is
#'   rounded to whole fish.
#' @param p The quantile.
#'
#' @return A number.
#' @export
linf_from_catch <- function(ldist, p = 1) {
  as.numeric(stats::quantile(rep(ldist$length, round(ldist$n)), p))
}

#' @title Harvest rate proxy of the chr rule
#' @description The harvest rate proxy of the constant harvest rate (chr)
#'   rule (ICES 2025, method 2.2): the mean of catch / index over the
#'   reference years in which the mean length of the catch above L_c is above
#'   L_F=M (f = L_mean / L_F=M > 1).
#'
#' @inheritParams mean_length_above
#' @param index A data frame with the columns `year` and `index` (see
#'   [index_series()]).
#' @param landings A data frame with the columns `year` and `landings`, in
#'   the units of the index.
#' @param Lc Length at first capture.
#' @param Linf L_inf (e.g. from [linf_from_catch()]).
#' @param hr_years Candidate reference years.
#'
#' @return A tibble by year with the columns `year`, `L` (mean length above
#'   L_c), `f`, `index`, `landings`, `hr` (landings / index) and `used` (a
#'   reference year with f > 1). The proxy is the attribute `hr_proxy`; the
#'   attributes `lc`, `linf` and `lfm` hold L_c, L_inf and L_F=M.
#' @export
harvest_rate_proxy <- function(ldist, index, landings, Lc, Linf, hr_years) {
  # NSE variables
  year <- mean_length <- L <- f <- hr <- NULL

  lfm <- target_reference_length(Lc = Lc, Linf = Linf)
  out <- ldist |>
    mean_length_above(Lc = Lc) |>
    dplyr::rename(L = mean_length) |>
    dplyr::mutate(f = L / lfm) |>
    dplyr::left_join(dplyr::select(index, year, index), by = "year") |>
    dplyr::left_join(landings, by = "year") |>
    dplyr::mutate(
      hr = landings / index,
      used = year %in% hr_years & f > 1
    )

  attr(out, "hr_proxy") <- mean(out$hr[out$used], na.rm = TRUE)
  attr(out, "lc") <- Lc
  attr(out, "linf") <- Linf
  attr(out, "lfm") <- lfm
  out
}
