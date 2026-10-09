# History rows and the assessment summary

Each MFRI stock repo keeps three history tables in `data/`, which the
advice sheets and tech reports read:

- `data/assessment.csv`: the assessment summary, one row per year and
  assessment year (the columns of
  `hafroreports::hr_assessment_template()`);
- `data/advice_hist.csv`: the advice for each fishing year;
- `data/tac_hist.csv`: the TAC, entered by hand after it is set.

For a category 3 stock, dlsrules makes this assessment’s rows:
[`assessment_summary()`](https://hafro.github.io/dlsrules/reference/assessment_summary.md)
for the summary and
[`advice_hist_rows()`](https://hafro.github.io/dlsrules/reference/advice_hist_rows.md)
for the advice.
[`rfb_ref_points_table()`](https://hafro.github.io/dlsrules/reference/rfb_ref_points_table.md)
gives the reference point table. The category 3 stocks that use them are
listed in
[`vignette("rfb-rule")`](https://hafro.github.io/dlsrules/articles/rfb-rule.md)
and
[`vignette("chr-rule")`](https://hafro.github.io/dlsrules/articles/chr-rule.md);
25-wit is the simplest example.

``` r

library(dlsrules)
```

## Simulated inputs

``` r

set.seed(1)
years <- 1985:2025
b <- round(2000 * exp(cumsum(c(0, rnorm(length(years) - 1, 0, 0.15)))))
survey_index <- rbind(
  data.frame(index = "smb_harv", year = years, b = b,
             b_cv = round(runif(length(years), 0.12, 0.3), 2),
             n = round(b / 0.6), n_cv = 0.2),
  data.frame(index = "smb_rec", year = years, b = round(b / 5), b_cv = 0.3,
             n = round(rlnorm(length(years), log(1500), 0.4)),
             n_cv = round(runif(length(years), 0.2, 0.4), 2))
)

z <- 0.12 + 0.05 * sin(seq_along(1990:2024) / 4)
ldist <- expand.grid(length = 20:70, year = 1990:2024)
ldist$n <- round(
  2000 * plogis((ldist$length - 32) / 1.5) *
    exp(-z[ldist$year - 1989] * (ldist$length - 32) / 1.2 * (ldist$length > 32))
)
ldist <- ldist[, c("year", "length", "n")]

assessment_year <- 2025
ref_points <- ref_points_iloss(
  list(K = 0.147, Linf = 62.1, Lc = 33, F_msy_proxy = 1),
  index_series(survey_index, "smb_harv", year_end = assessment_year),
  method = "min"
)
prognosis <- rfb_advice(
  index_series(survey_index, "smb_harv"), ldist, ref_points,
  prev_tac = 1659, assessment_year = assessment_year
)
```

## Assessment summary

For a category 3 stock the summary shows the biomass index as SSB, a
recruitment index (abundance), and a fishing pressure measure as F or
HR, each with 95% intervals where it has a CV.

For an rfb stock F is the fishing pressure proxy L_(F=M) / L_(mean)
(F_(MSY) proxy = 1).
[`fproxy_series()`](https://hafro.github.io/dlsrules/reference/fproxy_series.md)
gives it by year; the years are arguments, because they change the
table:

``` r

fp <- fproxy_series(
  ldist,
  Lc = ref_points$Lc,
  Linf = ref_points$Linf,
  year_start = -Inf,
  year_end = assessment_year - 1
)
tail(fp, 3)
#> # A tibble: 3 × 4
#>    year mean_length     f F_proxy
#>   <int>       <dbl> <dbl>   <dbl>
#> 1  2022        40.8  1.01   0.987
#> 2  2023        41.1  1.02   0.981
#> 3  2024        41.4  1.03   0.973

rows <- assessment_summary(
  survey_index,
  ssb_index = "smb_harv",
  rec_index = "smb_rec",
  fishing_pressure = fp,
  species = 25,
  assessment_year = assessment_year,
  ssb_ci = "lognormal",
  rec_ci = "lognormal"
)
tail(rows, 3)
#> # A tibble: 3 × 10
#>    year median_SSB low_SSB high_SSB median_recruitment low_recruitment
#>   <int>      <dbl>   <dbl>    <dbl>              <dbl>           <dbl>
#> 1  2023       2627   1775.    3888.               2235           1194.
#> 2  2024       3098   1935.    4959.               2051            974.
#> 3  2025       3474   1930.    6255.               1099            700.
#> # ℹ 4 more variables: high_recruitment <dbl>, median_F <dbl>, species <dbl>,
#> #   assessment_year <dbl>
```

The last year has no F: the catch sampling of the assessment year is not
complete. For a chr stock (04-whg), pass `landings` instead of (or as
well as) `fishing_pressure`: landings / SSB index is shown as
`median_HR` up to `landings_year_end` (default the year before the
assessment year).

``` r

landings <- data.frame(year = 1985:2024, landings = round(b[1:40] * 0.25))
tail(assessment_summary(
  survey_index, ssb_index = "smb_harv", rec_index = NULL,
  landings = landings, species = 4, assessment_year = assessment_year,
  ssb_ci = "normal"
), 3)
#> # A tibble: 3 × 7
#>    year median_SSB low_SSB high_SSB median_HR species assessment_year
#>   <int>      <dbl>   <dbl>    <dbl>     <dbl>   <dbl>           <dbl>
#> 1  2023       2627   1597.    3657.     0.250       4            2025
#> 2  2024       3098   1641.    4555.     0.250       4            2025
#> 3  2025       3474   1431.    5517.    NA           4            2025
```

The intervals are log-normal, x exp(∓1.96 CV), unless `"normal"` is
asked for, x (1 ∓ 1.96 CV), which can go below zero for a CV above 0.51.
04-whg keeps the normal interval for its SSB index, as its old code; the
other stocks use log-normal.

## Advice history rows

``` r

advice_hist_rows(prognosis, assessment_year)
#>   assessment_year advice_period advice advice_basis.en advice_basis.is
#> 1            2025     2025/2026   1975 Domestic advice Innlend ráðgjöf
advice_hist_rows(prognosis, assessment_year, n_years = 2)
#>   assessment_year advice_period advice advice_basis.en advice_basis.is
#> 1            2025     2025/2026   1975 Domestic advice Innlend ráðgjöf
#> 2            2026     2026/2027   1975 Domestic advice Innlend ráðgjöf
```

The advice is rounded to whole tonnes. With `n_years = 2` (biennial
advice, see
[`vignette("stock-choices")`](https://hafro.github.io/dlsrules/articles/stock-choices.md))
the same advice is entered for two fishing years. `basis_en` and
`basis_is` set the basis column (04-whg: “CHR rule” / “CHR reglan”).

## Reference point table

``` r

rfb_ref_points_table(ref_points)
#> # A tibble: 1 × 7
#>   I_lim I_trigger F_msy_proxy    Lc  Linf     K   trl
#>   <dbl>     <dbl>       <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1  1651      2311           1    33  62.1 0.147  40.3
```

I_(loss) (`I_lim`) and I_(trigger) are rounded to whole units of the
index (tonnes). `trl` is L_(F=M).

## Keep the published rows

The history files hold what was published, and a rerun must not change
it. A run on later data gives a slightly different advice for an
assessment year that is already published (a rerun of the cod assessment
gave 201,355 t instead of the published 201,674 t). Each stock repo
therefore has `R/hist.R` with `update_hist(hist, new, template = NULL)`,
built on `hafroreports::hr_update_hist()`. It adds the run’s rows only
for assessment years that are not in the file yet. Placeholder rows,
with every value `NA` (e.g. `2026,5a,NA` in `tac_hist.csv` before the
TAC is set), are not published, and the run’s rows replace them.

The rule on plain data frames, without hafroreports:

``` r

keep_published <- function(hist, new) {
  values <- setdiff(names(hist)[vapply(hist, is.numeric, logical(1))],
                    "assessment_year")
  placeholder <- rowSums(!is.na(hist[values])) == 0
  hist <- hist[!(placeholder & hist$assessment_year %in% new$assessment_year), ]
  new <- new[!new$assessment_year %in% hist$assessment_year, ]
  out <- rbind(hist, new)
  out <- out[order(out$assessment_year), ]
  rownames(out) <- NULL
  out
}

published <- data.frame(
  assessment_year = 2023:2024,
  advice_period = c("2023/2024", "2024/2025"),
  advice = c(1500, 1659),
  advice_basis.en = "Domestic advice",
  advice_basis.is = "Innlend ráðgjöf"
)
# A rerun of 2024 on today's data would give another number; the file keeps
# the published 1659 t and only 2025 is added
rerun <- rbind(
  transform(advice_hist_rows(prognosis, 2024), advice = 1702),
  advice_hist_rows(prognosis, 2025)
)
keep_published(published, rerun)
#>   assessment_year advice_period advice advice_basis.en advice_basis.is
#> 1            2023     2023/2024   1500 Domestic advice Innlend ráðgjöf
#> 2            2024     2024/2025   1659 Domestic advice Innlend ráðgjöf
#> 3            2025     2025/2026   1975 Domestic advice Innlend ráðgjöf
```

In the targets pipeline:

``` r
tar_target(
  advice_hist,
  update_hist(
    historical_advice_file,
    dlsrules::advice_hist_rows(rfb_prognosis, assessment_year,
                               n_years = advice_n_years)
  )
),
tar_target(
  assessment_hist,
  update_hist(
    template = hr_assessment_template(),
    historical_assessment_file,
    assessment_rows
  )
)
```

## Pitfalls

- **The files are read, not written.** The targets add this assessment’s
  rows in memory. After the advice is published, add the published rows
  to `data/*.csv` by hand, and check that the latest assessment’s row is
  there.
- **Header-only CSV files** (e.g. `tac_hist.csv` of a stock without a
  TAC) read as character columns. Give
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
  the column types.
- **Template by name:** pass `template = hr_assessment_template()` by
  name; `update_hist()`’s first argument is the history.
- **The F proxy years** (`fproxy_series(year_start, year_end)`) and the
  index of the SSB column change the history table and are fixed in the
  stock’s `config.R`
  ([`vignette("stock-choices")`](https://hafro.github.io/dlsrules/articles/stock-choices.md)).

## AI use

This vignette was drafted with Claude (Anthropic) in October 2026 and
has not yet been checked by a person (MFRI policy on the use of AI). The
data are simulated.
