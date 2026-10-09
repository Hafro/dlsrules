#' @title Assessment summary rows of a category 3 stock
#' @description The rows of this assessment for the assessment history table
#'   (one row per year): the biomass index as SSB, optionally a recruitment
#'   index, the fishing pressure proxy as F and/or catch / biomass index as
#'   the harvest rate, each with 95% intervals where they have a CV. The
#'   column names are those of the MFRI assessment history template
#'   (`median_SSB`, `low_SSB`, `high_SSB`, `median_recruitment`, ...,
#'   `median_F`, `median_HR`).
#'
#'   The intervals are log-normal, x exp(-/+ 1.96 CV), unless `"normal"` is
#'   asked for, x (1 -/+ 1.96 CV), which can be negative.
#'
#' @param survey_index A long data frame of survey indices with the columns
#'   `index` (series name), `year`, `b`, `b_cv` (biomass and its CV), `n` and
#'   `n_cv` (abundance and its CV).
#' @param ssb_index Name of the biomass index shown as SSB (biomass `b`).
#' @param rec_index Name of the index shown as recruitment (abundance `n`),
#'   or NULL for none.
#' @param fishing_pressure NULL, or a data frame with the columns `year` and
#'   `F_proxy` (e.g. from [fproxy_series()], with the years already chosen),
#'   shown as F.
#' @param landings NULL, or a data frame with the columns `year` and
#'   `landings` (in the units of the index). If given, landings / SSB index
#'   is shown as the harvest rate (`median_HR`) up to `landings_year_end`.
#' @param species Species number.
#' @param assessment_year The assessment year: years after it are left out.
#' @param ssb_ci,rec_ci `"lognormal"` or `"normal"` 95% intervals.
#' @param landings_year_end Last year of the harvest rate (the catches of
#'   the assessment year are not complete).
#'
#' @return A tibble with the columns `year`, `median_SSB`, `low_SSB`,
#'   `high_SSB`, (`median_recruitment`, `low_recruitment`,
#'   `high_recruitment`,) (`median_F`,) (`median_HR`,) `species` and
#'   `assessment_year`, one row per year of the SSB index.
#' @export
assessment_summary <- function(
  survey_index,
  ssb_index,
  rec_index = NULL,
  fishing_pressure = NULL,
  landings = NULL,
  species,
  assessment_year,
  ssb_ci = "lognormal",
  rec_ci = "lognormal",
  landings_year_end = assessment_year - 1
) {
  # NSE variables
  index <- year <- n <- n_cv <- b <- b_cv <- F_proxy <- median_SSB <- NULL

  ssb <- survey_index |>
    dplyr::filter(index == ssb_index, year <= assessment_year) |>
    ci_columns("b", "SSB", ssb_ci)
  out <- ssb
  if (!is.null(rec_index)) {
    rec <- survey_index |>
      dplyr::filter(index == rec_index, year <= assessment_year) |>
      ci_columns("n", "recruitment", rec_ci)
    out <- dplyr::left_join(out, rec, by = "year")
  }
  if (!is.null(fishing_pressure)) {
    out <- dplyr::left_join(
      out,
      dplyr::select(fishing_pressure, year, median_F = F_proxy),
      by = "year"
    )
  }
  if (!is.null(landings)) {
    out <- out |>
      dplyr::left_join(
        dplyr::filter(landings, year <= landings_year_end),
        by = "year"
      ) |>
      dplyr::mutate(median_HR = landings / median_SSB) |>
      dplyr::select(-landings)
  }
  dplyr::mutate(out, species = species, assessment_year = assessment_year)
}

# Median and 95% interval columns of one index: value column `value` with
# its CV in `<value>_cv`, named median_<name>, low_<name> and high_<name>
ci_columns <- function(index, value, name, ci) {
  ci <- match.arg(ci, c("lognormal", "normal"))
  x <- index[[value]]
  cv <- index[[paste0(value, "_cv")]]
  if (ci == "lognormal") {
    low <- x * exp(-1.96 * cv)
    high <- x * exp(1.96 * cv)
  } else {
    low <- x * (1 - cv * 1.96)
    high <- x * (1 + cv * 1.96)
  }
  out <- tibble::tibble(year = index$year, median = x, low = low, high = high)
  names(out)[-1] <- paste(names(out)[-1], name, sep = "_")
  out
}

#' @title Advice history rows
#' @description The rows of this assessment for the advice history table:
#'   the advised catch (rounded) of the prognosis for each fishing year it
#'   holds for, starting with the fishing year that starts in the assessment
#'   year.
#'
#' @param prognosis The prognosis from [rfb_advice()] or [chr_advice()] (a
#'   data frame with the columns `component` and `value`).
#' @param assessment_year The assessment year.
#' @param n_years Number of fishing years the advice holds for (2 for a
#'   biennial advice).
#' @param basis_en,basis_is Basis of the advice in English and Icelandic.
#'
#' @return A data frame with the columns `assessment_year`, `advice_period`
#'   (e.g. "2025/2026"), `advice`, `advice_basis.en` and `advice_basis.is`.
#' @export
advice_hist_rows <- function(
  prognosis,
  assessment_year,
  n_years = 1,
  basis_en = "Domestic advice",
  basis_is = "Innlend r\u00e1\u00f0gj\u00f6f"
) {
  k <- seq_len(n_years) - 1L
  data.frame(
    assessment_year = assessment_year + k,
    advice_period = paste(assessment_year + k, assessment_year + k + 1L, sep = "/"),
    advice = round(prognosis$value[prognosis$component == "catch_advice"]),
    advice_basis.en = basis_en,
    advice_basis.is = basis_is
  )
}

#' @title Reference point table of the rfb rule
#' @description The reference points of the rfb rule as a one-row table,
#'   with I_loss (`I_lim`) and I_trigger rounded to whole units of the index.
#'
#' @param ref_points A list with `I_lim`, `I_trigger`, `F_msy_proxy`, `Lc`,
#'   `Linf` and `K` (see [ref_points_iloss()]). L_F=M (`trl`) is
#'   `target_reference_length` if the list has it, otherwise computed from
#'   `Lc` and `Linf`.
#'
#' @return A tibble with the columns `I_lim`, `I_trigger`, `F_msy_proxy`,
#'   `Lc`, `Linf`, `K` and `trl`.
#' @export
rfb_ref_points_table <- function(ref_points) {
  trl <- ref_points$target_reference_length
  if (is.null(trl)) {
    trl <- target_reference_length(Lc = ref_points$Lc, Linf = ref_points$Linf)
  }
  tibble::tibble(
    I_lim = round(ref_points$I_lim),
    I_trigger = round(ref_points$I_trigger),
    F_msy_proxy = ref_points$F_msy_proxy,
    Lc = ref_points$Lc,
    Linf = ref_points$Linf,
    K = ref_points$K,
    trl = trl
  )
}
