# The rfb rule, step by step

The rfb rule (ICES 2025, method 2.1) sets the catch advice of a category
3 stock with slow growth (von Bertalanffy K \< 0.32) from a biomass
index and the length distribution of the catch:

``` math
A_{y+1} = A_y \times r \times f \times b \times m
```

- $`r`$: the index ratio, the mean of the last two index values over the
  mean of the three before them;
- $`f`$: the fishing pressure proxy, the mean length of the catch above
  L_(c) over the target length L_(F=M) = 0.75 L_(c) + 0.25 L_(inf);
- $`b`$: the biomass safeguard, min(1, I_(last) / I_(trigger)), with
  I_(trigger) = 1.4 I_(loss);
- $`m`$: the precautionary multiplier (0.95 for K \< 0.2, 0.9 for 0.2 ≤
  K \< 0.32);

followed by the stability clause (the advice changes by at most +20% /
−30%, unless $`b < 1`$).

The MFRI rfb stocks run it in their targets pipelines: 13-cas, 14-mon,
24-lem, 25-wit, 26-meg, 27-dab and 60-norway-redfish. This vignette goes
through the same steps on simulated data. The numbers are made up and
belong to no stock.

``` r

library(dlsrules)
```

## Simulated data

The pipelines keep the survey indices as one long table, one row per
index series and year, with biomass `b`, abundance `n` and their CVs. In
the stock repos it is built with
[`pax::pax_si_length_index()`](https://rdrr.io/pkg/pax/man/pax_si_index.html)
from the spring survey, and the series names say which length range they
cover (e.g. `smb_harv`, the biomass of fish over 30 cm in 25-wit).

``` r

set.seed(1)
years <- 1985:2025
b <- round(2000 * exp(cumsum(c(0, rnorm(length(years) - 1, 0, 0.15)))))
survey_index <- rbind(
  data.frame(
    index = "smb_harv", year = years, b = b,
    b_cv = round(runif(length(years), 0.12, 0.3), 2),
    n = round(b / 0.6), n_cv = 0.2
  ),
  data.frame(
    index = "smb_rec", year = years, b = round(b / 5), b_cv = 0.3,
    n = round(rlnorm(length(years), log(1500), 0.4)),
    n_cv = round(runif(length(years), 0.2, 0.4), 2)
  )
)
tail(survey_index[survey_index$index == "smb_harv", ], 6)
#>       index year    b b_cv    n n_cv
#> 36 smb_harv 2020 2993 0.12 4988  0.2
#> 37 smb_harv 2021 2812 0.25 4687  0.2
#> 38 smb_harv 2022 2650 0.14 4417  0.2
#> 39 smb_harv 2023 2627 0.20 4378  0.2
#> 40 smb_harv 2024 3098 0.24 5163  0.2
#> 41 smb_harv 2025 3474 0.30 5790  0.2
```

The catch length distribution: numbers by year and 1 cm length class.

``` r

z <- 0.12 + 0.05 * sin(seq_along(1990:2024) / 4)
ldist <- expand.grid(length = 20:70, year = 1990:2024)
ldist$n <- round(
  2000 * plogis((ldist$length - 32) / 1.5) *
    exp(-z[ldist$year - 1989] * (ldist$length - 32) / 1.2 * (ldist$length > 32))
)
ldist <- ldist[, c("year", "length", "n")]
head(ldist[ldist$year == 2024 & ldist$length >= 30, ])
#>      year length    n
#> 1745 2024     30  417
#> 1746 2024     31  678
#> 1747 2024     32 1000
#> 1748 2024     33 1165
#> 1749 2024     34 1230
#> 1750 2024     35 1207
```

## The catch length distribution from a pax database

In a stock repo the length distribution comes from the `pax_db` target
with
[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md).
The `ldist` table that
[`pax::pax_from_mar()`](https://rdrr.io/pkg/pax/man/pax_from_mar.html)
builds is **already raised** to the counted fish at import, so
[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
only rounds the lengths
([`pax::pax_ldist_scale_round()`](https://rdrr.io/pkg/pax/man/pax_ldist.html))
and does not raise the counts a second time. Building the distribution
with
[`pax::pax_ldist_by_year()`](https://rdrr.io/pkg/pax/man/pax_ldist.html)
and its default scaling raises twice: the length distributions of single
years are then a few percent too high in samples with counted fish
(found in the 04-whg port).

A toy database with two samples shows the call (pax is in Suggests, and
only
[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
needs it):

``` r

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbWriteTable(con, "station", data.frame(
  sample_id = 1:3,
  sampling_type = c(1, 8, 30), # two commercial samples, one survey tow
  year = 2024,
  mfdb_gear_code = c("BMT", "DSE", "BMT")
))
DBI::dbWriteTable(con, "ldist", data.frame(
  sample_id = c(1, 1, 2, 3),
  species = 25, sex = NA_integer_,
  length = c(35.4, 40.6, 41, 30),
  count = c(3, 2, 5, 100)
))
catch_ldist(
  dplyr::tbl(con, "station"),
  dplyr::tbl(con, "ldist"),
  gears = c("BMT", "DSE", "NPT"),
  year_start = 1976
)
#> # A tibble: 2 × 3
#>    year length     n
#>   <dbl>  <dbl> <dbl>
#> 1  2024     35     3
#> 2  2024     41     7
DBI::dbDisconnect(con, shutdown = TRUE)
```

The survey tow (sampling type 30) is left out; the defaults are the
commercial samples at sea and in port (1, 2, 8). The gears and the first
year are stock choices (25-wit: bottom trawl, Danish seine and Nephrops
trawl from 1976; 60-norway-redfish: bottom trawl from 1997). With
`by_gear = TRUE` the gear is kept, and
[`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)
selects from the collected table later (see
[`vignette("stock-choices")`](https://hafro.github.io/dlsrules/articles/stock-choices.md)).

## The components

### Index ratio, r

[`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md)
picks one series from the long table, in the form the rules take
(`year`, `index`). Cut it at the assessment year: the ratio uses the
last five rows it is given.

``` r

assessment_year <- 2025
index <- index_series(survey_index, "smb_harv", year_end = assessment_year)
calc_ratio(index, num = 2, den = 3)
#>        Component       value
#> IndexA    IndexA 3286.000000
#> IndexB    IndexB 2696.333333
#> ratio      ratio    1.218692
```

### Fishing pressure proxy, f

L_(F=M) comes from L_(c) and L_(inf). The rule uses the mean length
above L_(c) (strictly above) in the year before the assessment year
(`lag = 1`): the catch sampling of the assessment year is not complete
when the advice is given.

``` r

Lc <- 33
Linf <- 0.9 * 69 # 25-wit: 0.9 x the largest length in the catch
target_reference_length(Lc = Lc, Linf = Linf)
#> [1] 40.275
mean_length_above(ldist[ldist$year == assessment_year - 1, ], Lc = Lc)
#> # A tibble: 1 × 2
#>    year mean_length
#>   <int>       <dbl>
#> 1  2024        41.4
fishing_pressure_proxy(ldist, Linf = Linf, Lc = Lc,
                       assessment_year = assessment_year, lag = 1)$fpp
#> [1] 1.028187
```

If the length data has no rows for `assessment_year - lag`, f is `NaN`
and so is the advice. Check that the last year of the catch distribution
is the year you expect.

### I_(loss), I_(trigger) and the biomass safeguard, b

I_(loss) has no default: ICES (2025) says the lowest observed index
value, but the stocks differ
([`vignette("stock-choices")`](https://hafro.github.io/dlsrules/articles/stock-choices.md)).
[`calc_iloss()`](https://hafro.github.io/dlsrules/reference/calc_iloss.md)
gives it, and
[`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md)
adds `I_lim` (= I_(loss)), `I_lim_year` and `I_trigger` to the list of
reference points.

``` r

calc_iloss(index, method = "min")
#> $I_loss
#> [1] 1651
#> 
#> $year
#> [1] 1988
ref_points <- list(K = 0.147, Linf = Linf, Lc = Lc, F_msy_proxy = 1)
ref_points <- ref_points_iloss(ref_points, index, method = "min")
str(ref_points)
#> List of 7
#>  $ K          : num 0.147
#>  $ Linf       : num 62.1
#>  $ Lc         : num 33
#>  $ F_msy_proxy: num 1
#>  $ I_lim      : num 1651
#>  $ I_lim_year : int 1988
#>  $ I_trigger  : num 2311
biomass_safeguard(
  Inow = index$index[index$year == assessment_year],
  Itrigger = ref_points$I_trigger
)
#> [1] 1
```

Always pass `I_trigger` this way. If `ref_points` has neither
`I_trigger` nor `I_lim`,
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
falls back on 1.4 × the lowest value of the index it is given and only
says so with [`cat()`](https://rdrr.io/r/base/cat.html).

### Multiplier, m, and the stability clause

``` r

multiplier_lookup(ref_points$K)
#> [1] 0.95
stability_clause(tac = 2500, prev_tac = 1659, bsg = 1) # capped at +20%
#> [1] 1990.8
stability_clause(tac = 900, prev_tac = 1659, bsg = 1)  # capped at -30%
#> [1] 1161.3
stability_clause(tac = 900, prev_tac = 1659, bsg = 0.8) # not applied when b < 1
#> [1] 900
```

## The advice: `rfb_advice()`

[`rfb_advice()`](https://hafro.github.io/dlsrules/reference/rfb_advice.md)
cuts the index at the assessment year, runs
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
and returns the components with lower-case names and the assessment
year. This is the `rfb_prognosis` target of the stock repos.

``` r

prognosis <- rfb_advice(
  index_series(survey_index, "smb_harv"),
  ldist,
  ref_points = ref_points,
  prev_tac = 1659,
  assessment_year = assessment_year
)
prognosis
#> # A tibble: 17 × 4
#>    component                   value type                     assessment_year
#>    <chr>                       <dbl> <chr>                              <dbl>
#>  1 previous_catch_advice    1659     advice                              2025
#>  2 index_A                  3286     stock_biomass_trend                 2025
#>  3 index_B                  2696     stock_biomass_trend                 2025
#>  4 index_ratio                 1.22  stock_biomass_trend                 2025
#>  5 mean_catch_length          41.4   fishing_pressure_proxy              2025
#>  6 msy_proxy_length           40.3   fishing_pressure_proxy              2025
#>  7 fpp_ratio                   1.03  fishing_pressure_proxy              2025
#>  8 fpp_ratio_inv               0.973 fishing_pressure_proxy              2025
#>  9 last_index_value         3474     biomass_safeguard                   2025
#> 10 Itrigger                 2311     biomass_safeguard                   2025
#> 11 Iloss                    1651     biomass_safeguard                   2025
#> 12 biomass_safeguard           1     biomass_safeguard                   2025
#> 13 multiplier                  0.95  precautionary_multiplier            2025
#> 14 initial_catch_advice     1975.    advice                              2025
#> 15 stability_clause_applied    0     advice                              2025
#> 16 catch_advice             1975.    advice                              2025
#> 17 advice_change              19     advice                              2025
```

The product of the components gives the initial advice:

``` r

v <- setNames(prognosis$value, prognosis$component)
v[["previous_catch_advice"]] * v[["index_ratio"]] * v[["fpp_ratio"]] *
  v[["biomass_safeguard"]] * v[["multiplier"]]
#> [1] 1974.859
v[["initial_catch_advice"]]
#> [1] 1974.859
```

`index_A`, `index_B` and the I values are rounded in the table; the
advice is computed from the unrounded values.

In the stock repos the prognosis feeds
`hafroreports::hr_advice_table_rfb()` (the advice sheet table) and the
rfb figures of the tech report, and
[`advice_hist_rows()`](https://hafro.github.io/dlsrules/reference/advice_hist_rows.md)
([`vignette("history-tables")`](https://hafro.github.io/dlsrules/articles/history-tables.md)).

## Pitfalls

- **Double raising:** use
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  (or
  [`pax::pax_ldist_scale_round()`](https://rdrr.io/pkg/pax/man/pax_ldist.html)
  as its `ldist_tbl`) for the length distribution. The pax `ldist` table
  is already raised.
- **Index past the assessment year:** a later year in the index shifts
  `index_A` and `index_B`.
  [`rfb_advice()`](https://hafro.github.io/dlsrules/reference/rfb_advice.md)
  cuts it,
  [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
  does not.
- **K:**
  [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
  stops for K ≥ 0.32. Use the chr rule
  ([`vignette("chr-rule")`](https://hafro.github.io/dlsrules/articles/chr-rule.md))
  for 0.32 ≤ K \< 0.45.
- **L_(c) and L_(inf)** are fixed between benchmarks in the stock’s
  `config.R`. Don’t re-estimate them in each run: they change L_(F=M), f
  and the F proxy series of the history table.
- **The previous advice** is the advice for the fishing year that starts
  in the assessment year minus one, read from `data/advice_hist.csv`.
  For a biennial advice this is the second year of the previous advice
  ([`vignette("stock-choices")`](https://hafro.github.io/dlsrules/articles/stock-choices.md)).

## AI use

This vignette was drafted with Claude (Anthropic) in October 2026 and
has not yet been checked by a person (MFRI policy on the use of AI). The
data are simulated.
