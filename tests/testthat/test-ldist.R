test_that("rule_ldist() selects gears, years and lengths and sums by year", {
  ld <- test_ldist_by_gear()
  out <- rule_ldist(ld, gears = c("BMT", "DSE"))
  expect_named(out, c("year", "length", "n"))
  expect_equal(out$n, c(12, 8, 12, 8))
  expect_equal(rule_ldist(ld, max_length = 40)$length, c(30, 30))
  expect_equal(rule_ldist(ld, year_start = 2024)$year, c(2024, 2024))
})

test_that("rule_ldist() adds extra rows before the final sum", {
  ld <- test_ldist_by_gear()
  extra <- tibble::tibble(year = c(2024, 2025), length = c(30, 30), n = c(1, 7))
  out <- rule_ldist(ld, gears = "BMT", extra = extra)
  expect_equal(nrow(out), 5)
  expect_equal(out$n[out$year == 2024 & out$length == 30], 9)
  expect_equal(out$n[out$year == 2025], 7)
})

test_that("catch_ldist() rounds lengths and does not raise the counts", {
  skip_if_not_installed("pax")
  skip_if_not_installed("duckdb")
  skip_if_not_installed("dbplyr")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbWriteTable(con, "station", data.frame(
    sample_id = 1:4,
    sampling_type = c(1, 1, 8, 30),
    year = c(2023, 2024, 2024, 2024),
    mfdb_gear_code = c("BMT", "DSE", "BMT", "BMT")
  ))
  DBI::dbWriteTable(con, "ldist", data.frame(
    sample_id = c(1, 1, 2, 3, 3, 4),
    species = 25,
    sex = NA_integer_,
    length = c(30.4, 29.6, 40, 30, 41, 30),
    count = c(1.5, 2, 3, 4, 5, 100)
  ))
  out <- catch_ldist(dplyr::tbl(con, "station"), dplyr::tbl(con, "ldist"))
  expect_equal(out$year, c(2023, 2024, 2024, 2024))
  expect_equal(out$length, c(30, 30, 40, 41))
  expect_equal(out$n, c(3.5, 4, 3, 5))
  out <- catch_ldist(
    dplyr::tbl(con, "station"),
    dplyr::tbl(con, "ldist"),
    gears = "BMT",
    year_start = 2024,
    by_gear = TRUE
  )
  expect_named(out, c("year", "mfdb_gear_code", "length", "n"))
  expect_equal(out$n, c(4, 5))
})
