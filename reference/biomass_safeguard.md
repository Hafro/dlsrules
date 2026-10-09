# Biomass safeguard

Adjustment to reduce catch when the most recent index data is less than
Itrigger. Here, Itrigger is the breakpoint below which the stock state
deteriorates.

## Usage

``` r
biomass_safeguard(Inow, Itrigger)
```

## Arguments

- Inow:

  The most recent index value

- Itrigger:

  Itrigger which is defined as 1.4\*Iloss. Generally, Iloss is defined
  as the lowest observed index value.

## Value

Numeric scalar
