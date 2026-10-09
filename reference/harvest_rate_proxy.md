# Harvest rate proxy of the chr rule

The harvest rate proxy of the constant harvest rate (chr) rule (ICES
2025, method 2.2): the mean of catch / index over the reference years in
which the mean length of the catch above L_c is above L_F=M (f = L_mean
/ L_F=M \> 1).

## Usage

``` r
harvest_rate_proxy(ldist, index, landings, Lc, Linf, hr_years)
```

## Arguments

- ldist:

  A data frame with the columns `year`, `length` and `n` (e.g. from
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  or
  [`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)).

- index:

  A data frame with the columns `year` and `index` (see
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md)).

- landings:

  A data frame with the columns `year` and `landings`, in the units of
  the index.

- Lc:

  Length at first capture.

- Linf:

  L_inf (e.g. from
  [`linf_from_catch()`](https://hafro.github.io/dlsrules/reference/linf_from_catch.md)).

- hr_years:

  Candidate reference years.

## Value

A tibble by year with the columns `year`, `L` (mean length above L_c),
`f`, `index`, `landings`, `hr` (landings / index) and `used` (a
reference year with f \> 1). The proxy is the attribute `hr_proxy`; the
attributes `lc`, `linf` and `lfm` hold L_c, L_inf and L_F=M.
