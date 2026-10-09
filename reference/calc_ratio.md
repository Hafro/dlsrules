# Calculate index ratio

Calculates the ratio between the means of two adjacent periods for an
index (or anything called 'index')

## Usage

``` r
calc_ratio(data, num = 2, den = 3)
```

## Arguments

- data:

  A dataframe containing the columns 'year' and 'index'

- num:

  The number of years (backwards from the final year) to calculate the
  mean for 'indexA' e.g. for 2/3, num = 2

- den:

  The number of years (backwards from the 'num' years) to calculate the
  mean for 'indexB' e.g. for 2/3, num = 3

## Value

The ratio between indexA and indexB
