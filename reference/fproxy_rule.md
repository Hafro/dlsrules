# F-proxy rule for category 3 stocks

Calculates the advised catch based on the category 3 CHR rule.

## Usage

``` r
fproxy_rule(data, prev_tac, fproxy, Itrigger = NULL, stock_k)
```

## Arguments

- data:

  A data-frame containing the columns 'year' and 'index'

- prev_tac:

  The catch advice for the previous advisory year

- fproxy:

  f-proxy

- Itrigger:

  Itrigger which is defined as 1.4\*Iloss. Generally, Iloss is defined
  as the lowest observed index value (this is assumed if Itrigger is
  NULL)

- stock_k:

  The growth parameter 'K'

## Value

A dataframe with the advice for the current year and information used to
reach this value. 'final_advice' is the advice after the biomass
safeguard is considered, the 'initial_advice' is the value prior to this
step.
