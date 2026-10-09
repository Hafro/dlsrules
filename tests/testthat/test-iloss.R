test_that("index_series() picks and cuts one index", {
  si <- tibble::tibble(
    index = rep(c("a", "b"), each = 3),
    year = rep(2023:2025, 2),
    b = 1:6,
    n = 11:16
  )
  out <- index_series(si, "b", year_end = 2024)
  expect_named(out, c("year", "index"))
  expect_equal(out$index, 4:5)
  expect_equal(index_series(si, "a", value = "n")$index, 11:13)
})

test_that("calc_iloss() methods", {
  idx <- test_index()
  idx$index[1] <- NA
  expect_equal(calc_iloss(idx, "min"), list(I_loss = 250, year = 2018L))
  expect_equal(calc_iloss(idx, "second_min"), list(I_loss = 300, year = 2016L))
  expect_equal(calc_iloss(idx, "mean", years = 2016:2018)$I_loss, mean(c(300, 400, 250)))
  expect_null(calc_iloss(idx, "mean", years = 2016:2018)$year)
  expect_equal(calc_iloss(idx, "fixed", value = 123)$I_loss, 123)
  expect_error(calc_iloss(idx, "mean", years = 2010:2016), "no value in 2010")
  expect_error(calc_iloss(idx, "fixed"), "single numeric")
  expect_error(calc_iloss(idx), "")
})

test_that("ref_points_iloss() sets I_lim, I_lim_year and I_trigger", {
  rp <- ref_points_iloss(list(K = 0.1), test_index(), "min")
  expect_named(rp, c("K", "I_lim", "I_lim_year", "I_trigger"))
  expect_identical(rp$I_trigger, 1.4 * 250)
  rp <- ref_points_iloss(list(K = 0.1), test_index(), "mean", years = 2015:2016)
  expect_named(rp, c("K", "I_lim", "I_trigger"))
  rp <- ref_points_iloss(list(K = 0.1), test_index(), "min", itrigger_factor = 2)
  expect_equal(rp$I_trigger, 500)
})
