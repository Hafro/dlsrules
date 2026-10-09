# Calculate I_trigger

Calculates I_trigger from I_loss (i.e. I_trigger = I_loss\*1.4)

## Usage

``` r
calc_Itrigger(Iloss, factor = 1.4)
```

## Arguments

- Iloss:

  Iloss

- factor:

  I_trigger / I_loss (1.4 in ICES 2025)

## Value

I_trigger

## See also

[`calc_iloss()`](https://hafro.github.io/dlsrules/reference/calc_iloss.md)
and
[`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md)
for I_loss.
