# Biennial advice and stock-specific choices

The dlsrules helpers have few defaults on purpose: every choice that
changes the advice or the history tables is an argument, set in the
stock’s `config.R`. This vignette lists those choices, with what the
MFRI category 3 stocks chose, and shows the biennial advice.

``` r

library(dlsrules)
```

## The choices of the MFRI stocks

As set in the stocks’ `config.R` on their `dls-harmonise` branches
(October 2026):

| Stock | Rule | Index | Catch lengths (gears) | I_(loss) | F proxy series from | SSB interval | Advice years |
|----|----|----|----|----|----|----|----|
| 04-whg | chr | `smb_b40` | BMT, LLN, DSE, NPT, GIL | `"min"` | (HR instead) | normal | 1 |
| 13-cas | rfb | `smb_total` | BMT, LLN | `"min"` | 2007 | log-normal | 2 |
| 14-mon | rfb | `smb_b40` | BMT, NPT, DSE, GIL, LLN | `"mean"` 1985–1999 | all | log-normal | 2 |
| 24-lem | rfb | `smb_harv` | BMT, DSE, NPT; under 100 cm | `"min"` | all | log-normal | 2 |
| 25-wit | rfb | `smb_harv` | BMT, DSE, NPT | `"min"` | all | log-normal | 2 |
| 26-meg | rfb | `smb_harv` | BMT, DSE, NPT; survey lengths in years without catch samples | `"min"` | 1985 | log-normal | 2 |
| 27-dab | rfb | `smb_harv` | BMT, DSE, NPT | `"min"` | all | log-normal | 2 |
| 60-norway-redfish | rfb | `smb_total` | BMT from 1997 | `"second_min"` | all | log-normal | 2 |

The F proxy series ends the year before the assessment year in every
stock.

### Which rule

K decides: rfb for K \< 0.32
([`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
stops otherwise), chr for 0.32 ≤ K \< 0.45, and above that neither
(short-lived stocks). The multiplier follows K:

``` r

sapply(c(0.06, 0.147, 0.3), multiplier_lookup)
#> [1] 0.95 0.95 0.90
```

### I_(loss)

ICES (2025) defines I_(loss) as the lowest observed index value, which
is `method = "min"`. Two stocks keep the choice of their old assessment,
by decision of the stock coordinator: 14-mon uses the mean of 1985–1999,
and 60-norway-redfish the second lowest value. The method changes
I_(trigger), and with it the biomass safeguard:

``` r

set.seed(2)
index <- data.frame(
  year = 1985:2025,
  index = round(2000 * exp(cumsum(c(0, rnorm(40, 0, 0.12)))))
)
index$index[41] <- round(0.8 * min(index$index[1:40]) * 1.4)
sapply(
  list(
    min = calc_iloss(index, "min"),
    second_min = calc_iloss(index, "second_min"),
    mean = calc_iloss(index, "mean", years = 1985:1999),
    fixed = calc_iloss(index, "fixed", value = 1500)
  ),
  function(x) x$I_loss
)
#>        min second_min       mean      fixed 
#>   1796.000   1836.000   2285.733   1500.000
```

Here the last index value is below I_(trigger) with the lowest value as
I_(loss), so the biomass safeguard is below 1, and the stability clause
is not applied:

``` r

z <- 0.12 + 0.05 * sin(seq_along(1990:2024) / 4)
ldist <- expand.grid(length = 20:70, year = 1990:2024)
ldist$n <- round(
  2000 * plogis((ldist$length - 32) / 1.5) *
    exp(-z[ldist$year - 1989] * (ldist$length - 32) / 1.2 * (ldist$length > 32))
)
ldist <- ldist[, c("year", "length", "n")]

advice_by_method <- function(method, ...) {
  rp <- ref_points_iloss(list(K = 0.147, Linf = 62.1, Lc = 33), index,
                         method = method, ...)
  p <- rfb_advice(index, ldist, rp, prev_tac = 1659, assessment_year = 2025)
  setNames(p$value, p$component)[
    c("Iloss", "biomass_safeguard", "stability_clause_applied", "catch_advice")
  ]
}
rbind(
  min = advice_by_method("min"),
  second_min = advice_by_method("second_min"),
  mean = advice_by_method("mean", years = 1985:1999)
)
#>            Iloss biomass_safeguard stability_clause_applied catch_advice
#> min         1796         0.8001909                        0     840.9711
#> second_min  1836         0.7827575                        0     822.6493
#> mean        2286         0.6287448                        0     660.7875
```

### The length data of the rule

[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
takes the gears and the first year. To make the rule’s distribution from
a table collected by gear, use
[`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md):

``` r

ld_gear <- data.frame(
  year = rep(2023:2024, each = 4),
  mfdb_gear_code = rep(c("BMT", "DSE", "GIL", "BMT"), 2),
  length = c(30, 40, 50, 236, 31, 41, 51, 45),
  n = c(10, 5, 2, 1, 8, 6, 4, 2)
)
# 24-lem: gears of the rule, and lengths under 100 cm, which drops a
# mis-entered 236 cm fish
rule_ldist(ld_gear, gears = c("BMT", "DSE", "NPT"), max_length = 100)
#> # A tibble: 5 × 3
#>    year length     n
#>   <int>  <dbl> <dbl>
#> 1  2023     30    10
#> 2  2023     40     5
#> 3  2024     31     8
#> 4  2024     41     6
#> 5  2024     45     2
# 26-meg: add survey lengths in a year without catch samples of the gears
survey_ld <- data.frame(year = 2025, length = c(44, 48), n = c(3, 1))
rule_ldist(ld_gear, gears = c("BMT", "DSE", "NPT"), max_length = 100,
           extra = survey_ld)
#> # A tibble: 7 × 3
#>    year length     n
#>   <dbl>  <dbl> <dbl>
#> 1  2023     30    10
#> 2  2023     40     5
#> 3  2024     31     8
#> 4  2024     41     6
#> 5  2024     45     2
#> 6  2025     44     3
#> 7  2025     48     1
```

`lag` (default 1) is the number of years between the assessment year and
the year of the length data. Use 0 only when the lengths come from a
survey of the assessment year.

### L_(c) and L_(inf)

They are fixed in `config.R` until a benchmark: L_(c) at 50% of the
modal abundance (or a fixed value, 04-whg), L_(inf) from growth or from
the catch (25-wit and 27-dab: 0.9 × the largest length; 04-whg:
`linf_from_catch(p = 0.998)`). Re-estimating them each year changes
L_(F=M), the advice and the whole F proxy series.

### Intervals in the assessment summary

`assessment_summary(ssb_ci, rec_ci)`: log-normal for all stocks but
04-whg’s SSB index (normal, as its old code). See
[`vignette("history-tables")`](https://hafro.github.io/dlsrules/articles/history-tables.md).

## Biennial advice

Most of the rfb stocks give advice every second year, for two fishing
years. Three things follow.

**The assessment year** is the year of the advice, not the current year.
In the years between, the previous advice stands, and the pipeline must
reproduce it. 25-wit, 13-cas, 14-mon and 27-dab take the latest odd
year:

``` r

assessment_year_of <- function(today) {
  2025L + 2L * ((as.integer(format(today, "%Y")) - 2025L) %/% 2L)
}
assessment_year_of(as.Date(c("2025-06-01", "2026-10-09", "2027-03-01")))
#> [1] 2025 2025 2027
```

24-lem, 26-meg and 60-norway-redfish set `assessment_year <- 2025` by
hand. `data_year` (the last year with complete catches) is
`assessment_year - 1`; don’t use `assessment_year` for it.

**The previous advice** (`prev_tac`) is the advice for the fishing year
that starts the year before the assessment year, which for a biennial
advice is the second year of the previous advice:

``` r

prev_tac = readr::read_csv(historical_advice_file, show_col_types = FALSE) |>
  dplyr::filter(assessment_year == .env$assessment_year - 1) |>
  dplyr::pull(advice)
```

This needs a row for that year in `data/advice_hist.csv`, which the
previous assessment wrote with `n_years = 2`.

**The advice history** gets two rows:

``` r

prognosis <- rfb_advice(
  index, ldist,
  ref_points_iloss(list(K = 0.147, Linf = 62.1, Lc = 33), index, "min"),
  prev_tac = 1659, assessment_year = 2025
)
advice_hist_rows(prognosis, assessment_year = 2025, n_years = 2)
#>   assessment_year advice_period advice advice_basis.en advice_basis.is
#> 1            2025     2025/2026    841 Domestic advice Innlend ráðgjöf
#> 2            2026     2026/2027    841 Domestic advice Innlend ráðgjöf
```

## Pitfalls

- **Defaults of old calls:** when porting, check every argument the old
  code left out. The choices above reproduce each stock’s published
  advice; harmonising them is a decision for the stock coordinator, not
  a code change.
- **The year convention:** a history file that contains a newer
  assessment year than `assessment_year` makes the advice recompute the
  wrong year.
- **Survey index by length range:** the length ranges of the indices
  (`smb_harv`: over 30 cm in 25-wit) have exclusive ends, as tidypax
  had, and the station strata come from the fixed station list
  ([`pax::pax_si_strata_stations()`](https://rdrr.io/pkg/pax/man/pax_si_index.html)).
  Both change the index and so the advice.

## AI use

This vignette was drafted with Claude (Anthropic) in October 2026 and
has not yet been checked by a person (MFRI policy on the use of AI). The
data are simulated.
