# Fishing pressure proxy by year

The f of the rfb rule, L_mean / L_F=M, and its inverse, the fishing
pressure proxy L_F=M / L_mean that the assessment history shows as F
(F_MSY proxy = 1), for each year with length data.

Which years enter the series differs between stocks and changes the
history tables, so it is set by `year_start` and `year_end` rather than
by a default: most stocks stop the series the year before the assessment
year (`year_end = assessment_year - 1`), since the catch sampling of the
assessment year is not complete at the time of the assessment.

## Usage

``` r
fproxy_series(ldist, Lc, Linf, year_start = -Inf, year_end = Inf)
```

## Arguments

- ldist:

  A data frame with the columns `year`, `length` and `n` (e.g. from
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  or
  [`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)).

- Lc:

  Length at first capture: lengths strictly above it are used.

- Linf:

  L_inf of the von Bertalanffy growth equation.

- year_start, year_end:

  First and last year of the series (inclusive).

## Value

A tibble with the columns `year`, `mean_length` (L_mean above L_c), `f`
(L_mean / L_F=M) and `F_proxy` (L_F=M / L_mean).

## See also

[`target_reference_length()`](https://hafro.github.io/dlsrules/reference/target_reference_length.md)
for L_F=M.
