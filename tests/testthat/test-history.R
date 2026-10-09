test_survey_index <- function() {
  tibble::tibble(
    index = rep(c("harv", "rec"), each = 3),
    year = rep(2023:2025, 2),
    b = c(100, 200, 300, 1, 2, 3),
    b_cv = 0.2,
    n = c(10, 20, 30, 40, 50, 60),
    n_cv = 0.5
  )
}

test_that("assessment_summary() builds the history rows", {
  fp <- tibble::tibble(year = 2023:2024, F_proxy = c(0.9, 1.1), f = 0)
  out <- assessment_summary(
    test_survey_index(),
    ssb_index = "harv",
    rec_index = "rec",
    fishing_pressure = fp,
    species = 25,
    assessment_year = 2024
  )
  expect_named(out, c(
    "year", "median_SSB", "low_SSB", "high_SSB",
    "median_recruitment", "low_recruitment", "high_recruitment",
    "median_F", "species", "assessment_year"
  ))
  expect_equal(out$year, 2023:2024)
  expect_equal(out$low_SSB, c(100, 200) * exp(-1.96 * 0.2))
  expect_equal(out$high_recruitment, c(40, 50) * exp(1.96 * 0.5))
  expect_equal(out$median_F, c(0.9, 1.1))
})

test_that("assessment_summary() normal intervals and harvest rate", {
  lnd <- tibble::tibble(year = 2023:2025, landings = c(10, 20, 30))
  out <- assessment_summary(
    test_survey_index(),
    ssb_index = "harv",
    landings = lnd,
    species = 4,
    assessment_year = 2025,
    ssb_ci = "normal"
  )
  expect_equal(out$low_SSB, c(100, 200, 300) * (1 - 0.2 * 1.96))
  expect_equal(out$median_HR, c(0.1, 0.1, NA))
  expect_false("landings" %in% names(out))
})

test_that("advice_hist_rows() gives one row per fishing year", {
  prog <- tibble::tibble(component = c("index_a", "catch_advice"), value = c(1, 682.8))
  out <- advice_hist_rows(prog, 2025L, n_years = 2)
  expect_equal(out$assessment_year, 2025:2026)
  expect_equal(out$advice_period, c("2025/2026", "2026/2027"))
  expect_equal(out$advice, c(683, 683))
  out <- advice_hist_rows(prog, 2026, basis_en = "CHR rule", basis_is = "CHR reglan")
  expect_equal(out$advice_period, "2026/2027")
  expect_equal(out$advice_basis.en, "CHR rule")
})

test_that("rfb_ref_points_table() rounds the index reference points", {
  rp <- list(K = 0.1, Lc = 20, Linf = 36, F_msy_proxy = 1, I_lim = 10.6, I_trigger = 14.84)
  out <- rfb_ref_points_table(rp)
  expect_equal(out$I_lim, 11)
  expect_equal(out$I_trigger, 15)
  expect_equal(out$trl, 24)
})
