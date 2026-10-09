# Uncertainty cap

Limits the amount the advised catch can change upwards or downwards
between years. The previous year's advised catch +20% and -20% act as
bounds for the new advised catch.

## Usage

``` r
uncertainty_cap(tac, prev_tac, cap = 20)
```

## Arguments

- tac:

  The advised catch for the current assessment period

- prev_tac:

  Previous year's advised catch

- cap:

  Percentage change for the cap, assumed to be symmetrical

## Value

The advised catch after the uncertainty cap has been applied
