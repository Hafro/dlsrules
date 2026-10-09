# Advice from the chr rule

Runs
[`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
(the constant harvest rate rule) on the pieces of an assessment and
returns the prognosis with lower-case component names and the assessment
year.

## Usage

``` r
chr_advice(index, prev_tac, hr_proxy, ref_points, assessment_year)
```

## Arguments

- index:

  A data frame with the columns `year` and `index` (see
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md));
  years after the assessment year are left out, since the last index
  value is the one the advice is based on.

- prev_tac:

  The previous catch advice.

- hr_proxy:

  The harvest rate proxy (see
  [`harvest_rate_proxy()`](https://hafro.github.io/dlsrules/reference/harvest_rate_proxy.md)).

- ref_points:

  A list with `K` and `I_trigger` (see
  [`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md)).

- assessment_year:

  The assessment year.

## Value

A tibble with the columns `component`, `value`, `type` and
`assessment_year`, with the components of
[`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md).
