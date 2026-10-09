# Multiplier lookup

Multiplier applied to the harvest control rule to maintain the
probability of the biomass declining below Blim to less than 5%. Ranges
from 0 to 1.0.

## Usage

``` r
multiplier_lookup(stock_k)
```

## Arguments

- stock_k:

  The growth parameter 'K' (from von b equation)

## Value

A multiplier that is specific to the stock's K
