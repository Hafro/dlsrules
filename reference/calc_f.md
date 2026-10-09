# Calculate 'f' component

Calculates component 'f' for the rfb equation for category 3 stocks.
This is the ratio of the mean length (𝐿y−1 ) in the observed catch that
is above the length of first capture relative to the target reference
length (mean length/target reference length). The target reference
length is 𝐿fm = 0.75 Lc + 0.25 Linf, where Lc is defined as length at
50% of modal abundance

## Usage

``` r
calc_f(meanL, Lc, Linf)
```

## Arguments

- meanL:

  The mean length in the observed catch that is above the length of
  first capture

- Lc:

  The length at first capture (defined as the length at 50% of modal
  abundance)

- Linf:

  L-infinity from the Von Bertalanffy equation

## Value

The ratio between meanL and the target reference length
