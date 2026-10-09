# Advice from the rfb rule

Runs
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
on the pieces of an assessment and returns the prognosis with lower-case
component names and the assessment year.

The index is cut at the assessment year here:
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
takes the last five years of the index it is given for the index ratio,
so a later year would shift index A and B.

## Usage

``` r
rfb_advice(index, ldist, ref_points, prev_tac, assessment_year, lag = 1)
```

## Arguments

- index:

  A data frame with the columns `year` and `index` (see
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md)).

- ldist:

  Length distributions of the catch, a data frame with the columns
  `year`, `length` and `n` (see
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  and
  [`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)).

- ref_points:

  A list with `K`, `Linf`, `Lc` and `I_trigger` (see
  [`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md)).

- prev_tac:

  The previous catch advice.

- assessment_year:

  The assessment year.

- lag:

  Years between the assessment year and the year of the length data (see
  [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)).

## Value

A tibble with the columns `component`, `value`, `type` and
`assessment_year`, with the components of
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md).
