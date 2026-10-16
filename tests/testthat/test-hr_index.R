idx <- data.frame(year = 2024:2027, index = c(489, 277, 717, 1))

# The old Arnarfjordur advice/getData.R rule, as written
old_arn <- function(I, prev, hr = 0.346, ilim = 390) {
  bsg <- ifelse(I > ilim, 1, 0)
  initial <- hr * I
  flag <- ifelse(abs(1 - initial / prev) > 0.346, 1, 0)
  catch <- dplyr::case_when(
    flag == 0 & initial > prev ~ 1.2 * prev,
    flag == 0 & initial < prev ~ 0.8 * prev,
    TRUE ~ initial
  )
  bsg * catch
}
arn <- function(I, prev, ay = 2026) {
  d <- data.frame(year = ay, index = I)
  hr_index_advice(d, prev, 0.346, 390, ay,
    safeguard = "binary", safeguard_step = "final",
    stability_limits = c(0.8, 1.2), stability_threshold = 0.346,
    stability_when = "below", stability_set = TRUE, change = "new")
}
val <- function(res, comp) res$value[res$component == comp]

test_that("Arnarfjordur 2026: 0.346 x 717 = 248.082 t, change 100", {
  res <- hr_index_advice(idx, prev_tac = 0, hr_proxy = 0.346, I_trigger = 390,
    assessment_year = 2026, safeguard = "binary", safeguard_step = "final",
    stability_limits = c(0.8, 1.2), stability_threshold = 0.346,
    stability_when = "below", stability_set = TRUE, change = "new")
  expect_equal(val(res, "catch_advice"), 248.082)
  expect_equal(val(res, "biomass_index"), 717)
  expect_equal(val(res, "biomass_safeguard"), 1)
  expect_equal(val(res, "advice_change"), 100)
  expect_equal(val(res, "stability_clause_applied"), 0)
  expect_equal(res$assessment_year, rep(2026, 10))
})

test_that("The Arnarfjordur options reproduce the old code for many cases", {
  for (I in c(100, 389, 391, 500, 717, 2000)) {
    for (prev in c(0, 50, 169, 248, 300, 1000)) {
      expect_equal(val(arn(I, prev), "catch_advice"), old_arn(I, prev), info = paste(I, prev))
    }
  }
  # Below I_lim: 0, change -100
  res <- arn(277, 169, 2025)
  expect_equal(val(res, "catch_advice"), 0)
  expect_equal(val(res, "advice_change"), -100)
  # A small change is moved out to +20%: 0.346 x 489 = 169.2 from 166
  expect_equal(val(arn(489, 166), "catch_advice"), 1.2 * 166)
})

test_that("ICES-like defaults: ratio safeguard, stability clause only when b = 1", {
  res <- hr_index_advice(idx, prev_tac = 200, hr_proxy = 0.5, I_trigger = 600,
    assessment_year = 2026, stability_limits = c(0.8, 1.2))
  # 0.5 x 717 = 358.5, capped at 1.2 x 200
  expect_equal(val(res, "catch_advice"), 240)
  expect_equal(val(res, "stability_clause_applied"), 1)
  res <- hr_index_advice(idx, prev_tac = 200, hr_proxy = 0.5, I_trigger = 1000,
    assessment_year = 2026, stability_limits = c(0.8, 1.2))
  expect_equal(val(res, "catch_advice"), 0.5 * 717 * 0.717)
  expect_equal(val(res, "stability_clause_applied"), 0)
  res <- hr_index_advice(idx, prev_tac = 200, hr_proxy = 0.5, I_trigger = 100,
    assessment_year = 2026)
  expect_equal(val(res, "catch_advice"), 358.5)
  expect_true(is.na(val(res, "stability_test")))
  expect_equal(val(res, "advice_change"), round(100 * (358.5 / 200 - 1)))
})

test_that("Isafjardardjup 2026 options: no safeguard, clause above 0.5, previous 0 gives 0", {
  d <- data.frame(year = 2026, index = 267)
  res <- hr_index_advice(d, prev_tac = 0, hr_proxy = 0.5, I_trigger = 604,
    assessment_year = 2026, safeguard = "none", stability_limits = c(0.8, 1.2),
    stability_threshold = 0.5, stability_set = TRUE)
  expect_equal(val(res, "initial_catch_advice"), 133.5)
  expect_equal(val(res, "catch_advice"), 0)
  expect_equal(val(res, "biomass_safeguard"), 267 / 604)
})

test_that("Index after the assessment year is left out", {
  res <- hr_index_advice(idx, 0, 0.346, 390, 2026)
  expect_equal(val(res, "biomass_index"), 717)
  expect_error(hr_index_advice(idx, 0, 0.346, 390, 2020), "No index")
})

test_that("Isafjardardjup 2026 as the old getData.R: b binary but not applied, change NA", {
  d <- data.frame(year = 2026, index = 267)
  isa <- function(I, prev) {
    hr_index_advice(data.frame(year = 2026, index = I), prev, 0.5, 604, 2026,
      safeguard = "binary", apply_safeguard = FALSE,
      stability_limits = c(0.8, 1.2), stability_threshold = 0.5,
      stability_set = TRUE)
  }
  res <- isa(267, 0)
  expect_equal(val(res, "biomass_safeguard"), 0)
  expect_equal(val(res, "initial_catch_advice"), 133.5)
  expect_equal(val(res, "stability_test"), 1)
  expect_equal(val(res, "catch_advice"), 0)
  expect_true(is.na(val(res, "advice_change")))
  # The old rule, as written
  old_isa <- function(I, prev) {
    initial <- 0.5 * I
    flag <- ifelse(abs(1 - initial / prev) > 0.5, 1, 0)
    dplyr::case_when(
      flag == 1 & initial > prev ~ 1.2 * prev,
      flag == 1 & initial < prev ~ 0.8 * prev,
      TRUE ~ initial
    )
  }
  for (I in c(100, 267, 603, 605, 1500)) {
    for (prev in c(50, 133.5, 300, 1000)) {
      expect_equal(val(isa(I, prev), "catch_advice"), old_isa(I, prev), info = paste(I, prev))
    }
  }
  # Above I_trigger b = 1 and the advice is the same
  expect_equal(val(isa(1500, 700), "biomass_safeguard"), 1)
  # apply_safeguard = TRUE (default) applies the binary b
  expect_equal(val(hr_index_advice(d, 100, 0.5, 604, 2026, safeguard = "binary"), "catch_advice"), 0)
  expect_equal(val(isa(1000, 100), "advice_change"), 20)
})

test_that("Published inshore shrimp rule (HR x I x b, binary b, no clause) reproduces the advice", {
  # Isafjardardjup: published fishable index, previous advice and advice
  isa <- data.frame(
    year = 2021:2026, I = c(48, 1045, 102, 252, 534, 267),
    prev = c(586, 0, 523, 0, 0, 0), advice = c(0, 523, 0, 0, 0, 0)
  )
  for (k in seq_len(nrow(isa))) {
    res <- hr_index_advice(data.frame(year = isa$year[k], index = isa$I[k]), isa$prev[k],
      0.5, 604, isa$year[k], safeguard = "binary")
    # 0.5 x 1045 = 522.5, published 523 (rounded half up)
    expect_equal(floor(val(res, "catch_advice") + 0.5), isa$advice[k], info = isa$year[k])
  }
  # Arnarfjordur 2026 and 2025
  expect_equal(val(hr_index_advice(data.frame(year = 2026, index = 717), 0, 0.346, 390, 2026,
    safeguard = "binary", change = "new"), "catch_advice"), 248.082)
  expect_equal(val(hr_index_advice(data.frame(year = 2025, index = 277), 169, 0.346, 390, 2025,
    safeguard = "binary"), "catch_advice"), 0)
})
