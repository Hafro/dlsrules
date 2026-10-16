# Advice from a harvest rate times a survey index

The rule of the Icelandic shrimp stocks (inshore and offshore northern
shrimp): the advice is a fixed harvest rate (HR proxy) times the latest
survey biomass index, with a biomass safeguard at I_trigger and no
precautionary multiplier, optionally limited by a stability clause.
[`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
can't be used: it applies the multiplier from K and stops when K \<
0.32.

The published rule of the inshore shrimp stocks (Arnarfjordur,
Isafjardardjup) is A = I x HR x b with the binary safeguard and no
stability clause: `safeguard = "binary"` and the other defaults. The
remaining options keep the old scripts' code reproducible, including
leftover lines that are not the published method (October 2026: the
stability-clause lines of the old Arnarfjordur and Isafjardardjup
scripts, and their unapplied b), and their differences from the ICES
rules:

- `safeguard`:

  `"ratio"`: b = min(1, I / I_trigger), ICES; `"binary"`: b = 1 if I \>
  I_trigger, otherwise 0 (Arnarfjordur, where I_trigger = I_lim);
  `"none"`: b = min(1, I / I_trigger) is computed and shown but not
  applied.

- `apply_safeguard`:

  `TRUE` (default) applies b; `FALSE` computes b as `safeguard` says and
  shows it, but doesn't apply it (the old Isafjardardjup and
  Snaefellsnes scripts: b binary, not applied).

- `safeguard_step`:

  `"initial"`: the initial advice is HR x I x b and the stability clause
  applies only when b = 1, as ICES; `"final"`: the initial advice is HR
  x I and b multiplies the advice after the stability clause
  (Arnarfjordur).

- `stability_limits`:

  `NULL` (default) for no stability clause, or the lower and upper
  multipliers of the previous advice, e.g. `c(0.8, 1.2)`.

- `stability_threshold`, `stability_when`:

  The clause is applied only when the relative change of the initial
  advice from the previous one, \|A_initial / A_prev - 1\|, is `"above"`
  the threshold (Isafjardardjup and Snaefellsnes: 0.5) or `"below"` it
  or equal (Arnarfjordur: 0.346, the HR proxy, which caps small changes
  only). With the default threshold 0 and `"above"` it always applies.
  With a previous advice of 0 the change is infinite (or undefined when
  the initial advice is also 0, and then the clause is not applied).

- `stability_set`:

  `FALSE` (default): the clause bounds the advice between the limits;
  `TRUE`: when the clause applies, the advice is set to the upper limit
  if the initial advice is higher than the previous one and to the lower
  limit if it is lower, even if the change was smaller than the limits
  allow (the old Arnarfjordur and Isafjardardjup scripts; with their
  thresholds this only matters in Arnarfjordur, where changes under 20%
  are moved out to +/-20%).

- `change`:

  The advice change in the table: `"previous"` 100 x (A / A_prev - 1),
  `NA` when the previous advice is 0 (undefined; the old Isafjardardjup
  script); `"new"` 100 x (1 - A_prev / A), with an infinite value shown
  as -100 (the old Arnarfjordur table).

## Usage

``` r
hr_index_advice(
  index,
  prev_tac,
  hr_proxy,
  I_trigger,
  assessment_year,
  safeguard = c("ratio", "binary", "none"),
  apply_safeguard = TRUE,
  safeguard_step = c("initial", "final"),
  stability_limits = NULL,
  stability_threshold = 0,
  stability_when = c("above", "below"),
  stability_set = FALSE,
  change = c("previous", "new")
)
```

## Arguments

- index:

  A data frame with the columns `year` and `index` (see
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md));
  years after the assessment year are left out, and the last index value
  is the one the advice is based on.

- prev_tac:

  The previous catch advice.

- hr_proxy:

  The harvest rate proxy (target HR).

- I_trigger:

  The index trigger value (I_lim for the shrimp stocks).

- assessment_year:

  The assessment year.

- safeguard, apply_safeguard, safeguard_step, stability_limits,
  stability_threshold, stability_when, stability_set, change:

  See the description.

## Value

A tibble with the columns `component`, `value`, `type` and
`assessment_year`; the components `previous_catch_advice`,
`biomass_index`, `hr_proxy`, `I_trigger`, `biomass_safeguard`,
`initial_catch_advice`, `stability_test` (1 if the change passed the
threshold test, `NA` if undefined), `stability_clause_applied` (1 if the
clause changed the advice), `catch_advice` and `advice_change`.

## Examples

``` r
idx <- data.frame(year = 2024:2026, index = c(489, 277, 717))
# Arnarfjordur 2026 as published: binary safeguard, no clause
hr_index_advice(idx, prev_tac = 0, hr_proxy = 0.346, I_trigger = 390,
  assessment_year = 2026, safeguard = "binary", change = "new")
#> # A tibble: 10 × 4
#>    component                  value type              assessment_year
#>    <chr>                      <dbl> <chr>                       <dbl>
#>  1 previous_catch_advice      0     advice                       2026
#>  2 biomass_index            717     biomass_index                2026
#>  3 hr_proxy                   0.346 harvest_rate                 2026
#>  4 I_trigger                390     biomass_safeguard            2026
#>  5 biomass_safeguard          1     biomass_safeguard            2026
#>  6 initial_catch_advice     248.    advice                       2026
#>  7 stability_test            NA     advice                       2026
#>  8 stability_clause_applied   0     advice                       2026
#>  9 catch_advice             248.    advice                       2026
#> 10 advice_change            100     advice                       2026
# The old advice/getData.R as written (with its leftover clause lines)
hr_index_advice(idx, prev_tac = 0, hr_proxy = 0.346, I_trigger = 390,
  assessment_year = 2026, safeguard = "binary", safeguard_step = "final",
  stability_limits = c(0.8, 1.2), stability_threshold = 0.346,
  stability_when = "below", stability_set = TRUE, change = "new")
#> # A tibble: 10 × 4
#>    component                  value type              assessment_year
#>    <chr>                      <dbl> <chr>                       <dbl>
#>  1 previous_catch_advice      0     advice                       2026
#>  2 biomass_index            717     biomass_index                2026
#>  3 hr_proxy                   0.346 harvest_rate                 2026
#>  4 I_trigger                390     biomass_safeguard            2026
#>  5 biomass_safeguard          1     biomass_safeguard            2026
#>  6 initial_catch_advice     248.    advice                       2026
#>  7 stability_test             0     advice                       2026
#>  8 stability_clause_applied   0     advice                       2026
#>  9 catch_advice             248.    advice                       2026
#> 10 advice_change            100     advice                       2026
# ICES-like: safeguard ratio, stability clause always
hr_index_advice(idx, prev_tac = 200, hr_proxy = 0.346, I_trigger = 390,
  assessment_year = 2026, stability_limits = c(0.8, 1.2))
#> # A tibble: 10 × 4
#>    component                  value type              assessment_year
#>    <chr>                      <dbl> <chr>                       <dbl>
#>  1 previous_catch_advice    200     advice                       2026
#>  2 biomass_index            717     biomass_index                2026
#>  3 hr_proxy                   0.346 harvest_rate                 2026
#>  4 I_trigger                390     biomass_safeguard            2026
#>  5 biomass_safeguard          1     biomass_safeguard            2026
#>  6 initial_catch_advice     248.    advice                       2026
#>  7 stability_test             1     advice                       2026
#>  8 stability_clause_applied   1     advice                       2026
#>  9 catch_advice             240     advice                       2026
#> 10 advice_change             20     advice                       2026
```
