# dlsrules

A set of functions to run the empirical DLS rules for category 3 stocks

Documentation and vignettes: <https://hafro.github.io/dlsrules/> (the
rfb rule step by step, the chr rule, the history rows, and the
stock-specific choices and biennial advice).

## Installation

To install dlsrules run:

``` r

remotes::install_github("Hafro/dlsrules")
```

The package moved from the MFRI GitLab (demersal-division/dlsrules) to
GitHub in October 2026.

## Demonstation

A demonstation assessment of bling is found in folder ‘demos’

## Workflow for a category 3 stock

The rules
([`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md),
[`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md),
[`two_over_three()`](https://hafro.github.io/dlsrules/reference/two_over_three.md),
…) take plain data frames. The helpers below take the pieces of an
assessment and are what the MFRI stock repositories (targets pipelines)
call; everything that differs between stocks is an argument, set in the
stock’s `config.R`.

``` r

library(dlsrules)
pcon <- pax::pax_connect("pax_db.duckdb")

# Length distributions of the catch for the rule (pax in Suggests)
ldist <- catch_ldist(
  dplyr::tbl(pcon, "station"),
  dplyr::tbl(pcon, "ldist"),
  gears = c("BMT", "DSE", "NPT"),
  year_start = 1976
)

# The biomass index of the rule, from a long table of survey indices
# (columns index, year, b, b_cv, n, n_cv)
index <- index_series(survey_index, "smb_harv", year_end = 2025)

# I_loss and I_trigger: the method differs between stocks
ref_points <- list(K = 0.147, Linf = 62.1, Lc = 33, F_msy_proxy = 1)
ref_points <- ref_points_iloss(ref_points, index, method = "min")

# The advice (index cut at the assessment year inside)
prognosis <- rfb_advice(index, ldist, ref_points, prev_tac = 1659,
                        assessment_year = 2025)

# History table rows
fp <- fproxy_series(ldist, Lc = 33, Linf = 62.1, year_end = 2024)
rows <- assessment_summary(survey_index, ssb_index = "smb_harv",
                           rec_index = "smb_rec", fishing_pressure = fp,
                           species = 25, assessment_year = 2025)
advice_rows <- advice_hist_rows(prognosis, 2025, n_years = 2)
```

For the chr rule,
[`harvest_rate_proxy()`](https://hafro.github.io/dlsrules/reference/harvest_rate_proxy.md)
gives the harvest rate proxy and
[`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
the advice.

The stock-specific choices, and why they are arguments rather than
defaults: the I_loss method
([`calc_iloss()`](https://hafro.github.io/dlsrules/reference/calc_iloss.md):
lowest, second lowest, mean of years or fixed value), the years and
gears of the F-proxy series
([`fproxy_series()`](https://hafro.github.io/dlsrules/reference/fproxy_series.md),
[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md),
[`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)),
and normal or log-normal intervals
([`assessment_summary()`](https://hafro.github.io/dlsrules/reference/assessment_summary.md)).
Each changes the advice or the history tables.
