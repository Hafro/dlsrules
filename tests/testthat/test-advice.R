test_that("rfb_advice() is rfb_rule() with lower-case names, cut at the assessment year", {
  ld <- rule_ldist(test_ldist_by_gear())
  rp <- list(K = 0.15, Linf = 60, Lc = 29, I_trigger = 300)
  idx <- rbind(test_index(), data.frame(year = 2026, index = 1))
  res <- rfb_advice(idx, ld, rp, prev_tac = 100, assessment_year = 2024)
  ref <- rfb_rule(rp, as.data.frame(test_index()), as.data.frame(ld), 100, 2024) |>
    dplyr::rename_with(tolower) |>
    dplyr::mutate(assessment_year = 2024)
  expect_identical(res, ref)
})

test_that("chr_advice() is fproxy_rule() with lower-case names", {
  rp <- list(K = 0.38, I_trigger = 350)
  idx <- rbind(test_index(), data.frame(year = 2026, index = 1))
  res <- chr_advice(idx, prev_tac = 100, hr_proxy = 0.2, ref_points = rp, assessment_year = 2025)
  ref <- fproxy_rule(as.data.frame(test_index()), 100, 0.2, 350, 0.38) |>
    dplyr::rename_with(tolower) |>
    dplyr::mutate(assessment_year = 2025)
  expect_identical(res, ref)
  expect_equal(res$value[res$component == "catch_advice"], 850 * 0.2 * 0.5)
})

test_that("rfb_rule() f is the fproxy_series() f of the year before", {
  ld <- rule_ldist(test_ldist_by_gear())
  rp <- list(K = 0.15, Linf = 60, Lc = 29, I_trigger = 100)
  res <- rfb_advice(test_index(), ld, rp, prev_tac = 100, assessment_year = 2025)
  fs <- fproxy_series(ld, Lc = 29, Linf = 60)
  expect_identical(res$value[res$component == "fpp_ratio"], fs$f[fs$year == 2024])
})
