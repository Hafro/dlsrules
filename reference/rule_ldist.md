# Length distributions of the rule from a collected table

Selects the gears, years and lengths of the rule from a length
distribution by year, gear and length (such as
`catch_ldist(by_gear = TRUE)`), sums it by year and length, and
optionally adds other length distributions (e.g. survey lengths in years
without catch samples).

## Usage

``` r
rule_ldist(
  ldist,
  gears = NULL,
  year_start = NULL,
  max_length = NULL,
  extra = NULL
)
```

## Arguments

- ldist:

  A data frame with the columns `year`, `length` and `n`, and
  `mfdb_gear_code` if `gears` is given.

- gears:

  mfdb gear codes to keep, or NULL for all.

- year_start:

  First year to keep, or NULL for all.

- max_length:

  Keep lengths strictly below this, or NULL for all (e.g. to drop a
  mis-entered length).

- extra:

  NULL, or a data frame with the columns `year`, `length` and `n` that
  is added to the selected distribution before the final sum.

## Value

A tibble with the columns `year`, `length` and `n`, sorted by year and
length.
