# Add I_loss and I_trigger to the reference points

Sets `I_lim` (= I_loss, see
[`calc_iloss()`](https://hafro.github.io/dlsrules/reference/calc_iloss.md)),
`I_lim_year` (for the methods that pick one year) and `I_trigger` =
`itrigger_factor` x I_loss in a list of reference points, as
[`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
and the history and report tables use them.

## Usage

``` r
ref_points_iloss(
  ref_points,
  index,
  method,
  years = NULL,
  value = NULL,
  itrigger_factor = 1.4
)
```

## Arguments

- ref_points:

  A list of reference points (e.g. `K`, `Linf`, `Lc`).

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

- itrigger_factor:

  I_trigger / I_loss (1.4 in ICES 2025).

## Value

`ref_points` with the elements `I_lim`, (`I_lim_year`,) and `I_trigger`
set.
