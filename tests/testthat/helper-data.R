# Small length distribution: two years, three gears
test_ldist_by_gear <- function() {
  tibble::tibble(
    year = rep(c(2023, 2024), each = 6),
    mfdb_gear_code = rep(c("BMT", "BMT", "DSE", "DSE", "GIL", "GIL"), 2),
    length = rep(c(30, 40), 6),
    n = c(10, 5, 2, 3, 1, 100, 8, 6, 4, 2, 50, 1)
  )
}

test_index <- function() {
  tibble::tibble(
    year = 2015:2024,
    index = c(500, 300, 400, 250, 600, 700, 650, 800, 900, 850)
  )
}
