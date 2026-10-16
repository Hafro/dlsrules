#' @title Advice from the rfb rule
#' @description Runs [rfb_rule()] on the pieces of an assessment and returns
#'   the prognosis with lower-case component names and the assessment year.
#'
#'   The index is cut at the assessment year here: [rfb_rule()] takes the
#'   last five years of the index it is given for the index ratio, so a
#'   later year would shift index A and B.
#'
#' @param index A data frame with the columns `year` and `index` (see
#'   [index_series()]).
#' @param ldist Length distributions of the catch, a data frame with the
#'   columns `year`, `length` and `n` (see [catch_ldist()] and
#'   [rule_ldist()]).
#' @param ref_points A list with `K`, `Linf`, `Lc` and `I_trigger` (see
#'   [ref_points_iloss()]).
#' @param prev_tac The previous catch advice.
#' @param assessment_year The assessment year.
#' @param lag Years between the assessment year and the year of the length
#'   data (see [rfb_rule()]).
#' @param digits Rounding of the shown components (see [rfb_rule()]).
#'
#' @return A tibble with the columns `component`, `value`, `type` and
#'   `assessment_year`, with the components of [rfb_rule()].
#' @export
rfb_advice <- function(
  index,
  ldist,
  ref_points,
  prev_tac,
  assessment_year,
  lag = 1,
  digits = c(index = 0, ratio = NA, index_value = 0, change = 0)
) {
  index <- index[index$year <= assessment_year, c("year", "index")]
  out <- rfb_rule(
    ref_points = ref_points,
    index_data = as.data.frame(index),
    len_data = as.data.frame(ldist),
    prev_tac = prev_tac,
    assessment_year = assessment_year,
    lag = lag,
    digits = digits
  )
  names(out) <- tolower(names(out))
  out$assessment_year <- assessment_year
  out
}

#' @title Advice from the chr rule
#' @description Runs [fproxy_rule()] (the constant harvest rate rule) on the
#'   pieces of an assessment and returns the prognosis with lower-case
#'   component names and the assessment year.
#'
#' @param index A data frame with the columns `year` and `index` (see
#'   [index_series()]); years after the assessment year are left out, since
#'   the last index value is the one the advice is based on.
#' @param prev_tac The previous catch advice.
#' @param hr_proxy The harvest rate proxy (see [harvest_rate_proxy()]).
#' @param ref_points A list with `K` and `I_trigger` (see
#'   [ref_points_iloss()]).
#' @param assessment_year The assessment year.
#'
#' @return A tibble with the columns `component`, `value`, `type` and
#'   `assessment_year`, with the components of [fproxy_rule()].
#' @export
chr_advice <- function(index, prev_tac, hr_proxy, ref_points, assessment_year) {
  index <- index[index$year <= assessment_year, c("year", "index")]
  out <- fproxy_rule(
    data = as.data.frame(index),
    prev_tac = prev_tac,
    fproxy = hr_proxy,
    Itrigger = ref_points$I_trigger,
    stock_k = ref_points$K
  )
  names(out) <- tolower(names(out))
  out$assessment_year <- assessment_year
  out
}
