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

test_that("rfb digits round only the shown components, as the old sea urchin rfb_rule_round()", {
  # The 2006-2024 sea urchin CPUE index (relative, near 1) and a length
  # distribution whose 2024 mean above Lc is 6.44 cm
  idx <- data.frame(
    year = 2006:2024,
    index = c(1.5349, 1.3080, 1.4070, 1.7297, 1.4736, 1.3877, 1.2701, 1.4242,
      1.4954, 1.3768, 1.6628, 1.4512, 1.2755, 1.0770, 1.7248989654252196,
      1.455695585467646, 2.2324198172542467, 1.6837508692488967, 1.922300473315151)
  )
  ld <- data.frame(year = 2024, length = c(5, 6.2, 6.68), n = c(10, 50, 50))
  rp <- list(K = 0.1, Linf = 8.5, Lc = 5.2, I_trigger = 1.512)
  plain <- rfb_advice(idx, ld, rp, prev_tac = 194, assessment_year = 2025)
  rounded <- rfb_advice(idx, ld, rp, prev_tac = 194, assessment_year = 2025,
    digits = c(index = 4, ratio = 4, index_value = 3, change = 2))
  v <- function(x, k) x$value[x$component == k]
  expect_equal(v(plain, "index_A"), 2)
  expect_equal(v(rounded, "index_A"), 1.803)
  expect_equal(v(rounded, "index_B"), 1.8043)
  expect_equal(v(rounded, "index_ratio"), 0.9993)
  expect_equal(v(rounded, "last_index_value"), 1.922)
  expect_equal(v(rounded, "Iloss"), 1.08)
  expect_equal(v(rounded, "catch_advice"), v(plain, "catch_advice"))
  expect_equal(v(rounded, "advice_change"), round(v(plain, "catch_advice") / 194 * 100 - 100, 2))
  # Defaults unchanged
  expect_identical(
    rfb_advice(idx, ld, rp, prev_tac = 194, assessment_year = 2025, digits = c(index = 0)),
    plain
  )
})
