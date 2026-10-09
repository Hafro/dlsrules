# L_inf from the catch length distribution

A quantile of the individual lengths in the catch (all years), used as
L_inf when the growth parameters are not reliable (the largest length
when `p = 1`).

## Usage

``` r
linf_from_catch(ldist, p = 1)
```

## Arguments

- ldist:

  A data frame with the columns `length` and `n`; `n` is rounded to
  whole fish.

- p:

  The quantile.

## Value

A number.
