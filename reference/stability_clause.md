# Stability clause

Limits the amount the advised catch can change upwards or downwards
between years. The previous year's advised catch +20% and -30% act as
bounds for the new advised catch.

## Usage

``` r
stability_clause(tac, prev_tac, bsg)
```

## Arguments

- tac:

  The advised catch for the current assessment period (the advised catch
  resulting from the rfb rule)

- prev_tac:

  Previous year's advised catch

- bsg:

  Biomass safeguard (obtained from the function 'biomass_safeguard')

## Value

The advised catch after the stability clause has been applied
