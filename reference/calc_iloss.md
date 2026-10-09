# I_loss from an index series

I_loss, the index value below which the stock is considered to
deteriorate, from the biomass index of the rule. ICES (2025) defines it
as the lowest observed index value, but stocks differ, and the choice
changes I_trigger and the biomass safeguard, so the method has no
default:

- `"min"`: the lowest index value.

- `"second_min"`: the second lowest index value.

- `"mean"`: the mean of the index in `years` (all of them must be in the
  index).

- `"fixed"`: `value`.

Missing index values are ignored.

## Usage

``` r
calc_iloss(index, method, years = NULL, value = NULL)
```

## Arguments

- index:

  A data frame with the columns `year` and `index`, cut at the
  assessment year (see
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md)).

- method:

  One of `"min"`, `"second_min"`, `"mean"` or `"fixed"`.

- years:

  The years of the mean (method `"mean"`).

- value:

  The value (method `"fixed"`).

## Value

A list with `I_loss` and `year`, the year of the index value used (NULL
for the methods `"mean"` and `"fixed"`).
