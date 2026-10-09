# Mean length above the length at first capture

Mean length of the catch above L_c by year: the L_mean of the fishing
pressure proxy of the rfb rule (ICES 2025, method 2.1) and of the
harvest rate proxy of the chr rule (method 2.2).

## Usage

``` r
mean_length_above(ldist, Lc)
```

## Arguments

- ldist:

  A data frame with the columns `year`, `length` and `n` (e.g. from
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  or
  [`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)).

- Lc:

  Length at first capture: lengths strictly above it are used.

## Value

A tibble with the columns `year` and `mean_length`.
