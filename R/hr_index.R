#' @title Advice from a harvest rate times a survey index
#' @description The rule of the Icelandic shrimp stocks (inshore and
#'   offshore northern shrimp): the advice is a fixed harvest rate (HR proxy)
#'   times the latest survey biomass index, with a biomass safeguard at
#'   I_trigger and no precautionary multiplier, optionally limited by a
#'   stability clause. [chr_advice()] can't be used: it applies the
#'   multiplier from K and stops when K < 0.32.
#'
#'   The options keep the old scripts reproducible, including their
#'   differences from the ICES rules:
#'   \describe{
#'     \item{`safeguard`}{`"ratio"`: b = min(1, I / I_trigger), ICES;
#'       `"binary"`: b = 1 if I > I_trigger, otherwise 0 (Arnarfjordur, where
#'       I_trigger = I_lim); `"none"`: b is computed and shown but not applied
#'       (Isafjardardjup, Snaefellsnes and offshore shrimp in 2026).}
#'     \item{`safeguard_step`}{`"initial"`: the initial advice is HR x I x b
#'       and the stability clause applies only when b = 1, as ICES;
#'       `"final"`: the initial advice is HR x I and b multiplies the advice
#'       after the stability clause (Arnarfjordur).}
#'     \item{`stability_limits`}{`NULL` (default) for no stability clause, or
#'       the lower and upper multipliers of the previous advice, e.g.
#'       `c(0.8, 1.2)`.}
#'     \item{`stability_threshold`, `stability_when`}{The clause is applied
#'       only when the relative change of the initial advice from the
#'       previous one, |A_initial / A_prev - 1|, is `"above"` the threshold
#'       (Isafjardardjup and Snaefellsnes: 0.5) or `"below"` it or equal
#'       (Arnarfjordur: 0.346, the HR proxy, which caps small changes only).
#'       With the default threshold 0 and `"above"` it always applies. With
#'       a previous advice of 0 the change is infinite (or undefined when
#'       the initial advice is also 0, and then the clause is not applied).}
#'     \item{`stability_set`}{`FALSE` (default): the clause bounds the
#'       advice between the limits; `TRUE`: when the clause applies, the
#'       advice is set to the upper limit if the initial advice is higher
#'       than the previous one and to the lower limit if it is lower, even
#'       if the change was smaller than the limits allow (the old
#'       Arnarfjordur and Isafjardardjup scripts; with their thresholds this
#'       only matters in Arnarfjordur, where changes under 20% are moved out
#'       to +/-20%).}
#'     \item{`change`}{The advice change in the table: `"previous"` 100 x
#'       (A / A_prev - 1); `"new"` 100 x (1 - A_prev / A), with an infinite
#'       value shown as -100 (the old shrimp tables).}
#'   }
#'
#' @param index A data frame with the columns `year` and `index` (see
#'   [index_series()]); years after the assessment year are left out, and
#'   the last index value is the one the advice is based on.
#' @param prev_tac The previous catch advice.
#' @param hr_proxy The harvest rate proxy (target HR).
#' @param I_trigger The index trigger value (I_lim for the shrimp stocks).
#' @param assessment_year The assessment year.
#' @param safeguard,safeguard_step,stability_limits,stability_threshold,stability_when,stability_set,change
#'   See the description.
#'
#' @return A tibble with the columns `component`, `value`, `type` and
#'   `assessment_year`; the components `previous_catch_advice`,
#'   `biomass_index`, `hr_proxy`, `I_trigger`, `biomass_safeguard`,
#'   `initial_catch_advice`, `stability_test` (1 if the change passed the
#'   threshold test, `NA` if undefined), `stability_clause_applied` (1 if
#'   the clause changed the advice), `catch_advice` and `advice_change`.
#' @examples
#' idx <- data.frame(year = 2024:2026, index = c(489, 277, 717))
#' # Arnarfjordur 2026, as the old advice/getData.R
#' hr_index_advice(idx, prev_tac = 0, hr_proxy = 0.346, I_trigger = 390,
#'   assessment_year = 2026, safeguard = "binary", safeguard_step = "final",
#'   stability_limits = c(0.8, 1.2), stability_threshold = 0.346,
#'   stability_when = "below", stability_set = TRUE, change = "new")
#' # ICES-like: safeguard ratio, stability clause always
#' hr_index_advice(idx, prev_tac = 200, hr_proxy = 0.346, I_trigger = 390,
#'   assessment_year = 2026, stability_limits = c(0.8, 1.2))
#' @export
hr_index_advice <- function(
  index,
  prev_tac,
  hr_proxy,
  I_trigger,
  assessment_year,
  safeguard = c("ratio", "binary", "none"),
  safeguard_step = c("initial", "final"),
  stability_limits = NULL,
  stability_threshold = 0,
  stability_when = c("above", "below"),
  stability_set = FALSE,
  change = c("previous", "new")
) {
  safeguard <- match.arg(safeguard)
  safeguard_step <- match.arg(safeguard_step)
  stability_when <- match.arg(stability_when)
  change <- match.arg(change)
  if (!all(c("year", "index") %in% names(index))) {
    stop("index must have the columns 'year' and 'index'")
  }
  if (!is.null(stability_limits) && length(stability_limits) != 2) {
    stop("stability_limits must be NULL or c(lower, upper)")
  }
  index <- index[index$year <= assessment_year & !is.na(index$index), ]
  if (nrow(index) == 0) {
    stop("No index value up to the assessment year")
  }
  Inow <- index$index[which.max(index$year)]

  bsg <- switch(
    safeguard,
    ratio = min(1, Inow / I_trigger),
    binary = ifelse(Inow > I_trigger, 1, 0),
    none = min(1, Inow / I_trigger)
  )
  # The factor applied to the advice
  b_applied <- if (safeguard == "none") 1 else bsg

  initial <- hr_proxy * Inow
  if (safeguard_step == "initial") {
    initial <- initial * b_applied
  }

  tac <- initial
  test <- NA_real_
  applied <- 0
  if (!is.null(stability_limits)) {
    rel <- abs(initial / prev_tac - 1)
    test <- if (is.na(rel)) {
      NA_real_
    } else if (stability_when == "above") {
      as.numeric(rel > stability_threshold)
    } else {
      as.numeric(rel <= stability_threshold)
    }
    # ICES: no stability clause when the safeguard reduces the advice
    allowed <- !(safeguard_step == "initial" && b_applied < 1)
    if (isTRUE(test == 1) && allowed) {
      if (isTRUE(stability_set)) {
        tac <- if (initial > prev_tac) {
          stability_limits[2] * prev_tac
        } else if (initial < prev_tac) {
          stability_limits[1] * prev_tac
        } else {
          initial
        }
      } else {
        tac <- min(
          max(stability_limits[1] * prev_tac, initial),
          stability_limits[2] * prev_tac
        )
      }
    }
    applied <- as.numeric(tac != initial)
  }
  if (safeguard_step == "final") {
    tac <- b_applied * tac
  }

  adv_change <- if (change == "previous") {
    round(100 * (tac / prev_tac - 1))
  } else {
    x <- round(100 * (1 - prev_tac / tac))
    if (is.infinite(x)) -100 else x
  }

  tibble::tibble(
    component = c(
      "previous_catch_advice",
      "biomass_index",
      "hr_proxy",
      "I_trigger",
      "biomass_safeguard",
      "initial_catch_advice",
      "stability_test",
      "stability_clause_applied",
      "catch_advice",
      "advice_change"
    ),
    value = c(
      prev_tac,
      Inow,
      hr_proxy,
      I_trigger,
      bsg,
      initial,
      test,
      applied,
      tac,
      adv_change
    ),
    type = c(
      "advice",
      "biomass_index",
      "harvest_rate",
      rep("biomass_safeguard", 2),
      rep("advice", 5)
    ),
    assessment_year = assessment_year
  )
}
