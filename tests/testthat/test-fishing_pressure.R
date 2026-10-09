test_that("target_reference_length() is 0.75 Lc + 0.25 Linf", {
  expect_equal(target_reference_length(Lc = 40, Linf = 80), 50)
})

test_that("mean_length_above() uses lengths strictly above Lc", {
  ld <- rule_ldist(test_ldist_by_gear())
  out <- mean_length_above(ld, Lc = 30)
  expect_equal(out$mean_length, c(40, 40))
  out <- mean_length_above(ld, Lc = 29)
  expect_equal(out$mean_length[1], (30 * 13 + 40 * 108) / 121)
})

test_that("fproxy_series() keeps the years asked for", {
  ld <- rule_ldist(test_ldist_by_gear())
  out <- fproxy_series(ld, Lc = 29, Linf = 60, year_end = 2023)
  expect_equal(out$year, 2023)
  lfm <- target_reference_length(29, 60)
  expect_equal(out$f, out$mean_length / lfm)
  expect_equal(out$F_proxy, lfm / out$mean_length)
  expect_equal(nrow(fproxy_series(ld, Lc = 29, Linf = 60)), 2)
})

test_that("harvest_rate_proxy() averages catch / index over years with f > 1", {
  ld <- rule_ldist(test_ldist_by_gear())
  idx <- tibble::tibble(year = c(2023, 2024), index = c(100, 200))
  lnd <- tibble::tibble(year = c(2023, 2024), landings = c(10, 30))
  out <- harvest_rate_proxy(ld, idx, lnd, Lc = 29, Linf = 30, hr_years = 2023:2024)
  expect_named(out, c("year", "L", "f", "index", "landings", "hr", "used"))
  expect_true(all(out$used))
  expect_equal(attr(out, "hr_proxy"), mean(c(0.1, 0.15)))
  expect_equal(attr(out, "lfm"), target_reference_length(29, 30))
  out <- harvest_rate_proxy(ld, idx, lnd, Lc = 29, Linf = 30, hr_years = 2024)
  expect_equal(attr(out, "hr_proxy"), 0.15)
})

test_that("linf_from_catch() is a quantile of the individual lengths", {
  ld <- tibble::tibble(length = c(10, 20, 30), n = c(1, 1, 0.4))
  expect_equal(linf_from_catch(ld), 20)
  expect_equal(linf_from_catch(ld, 0.5), 15)
})
