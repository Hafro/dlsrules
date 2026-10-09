# Calculate 'f' component

Calculates component 'f' for the rfb equation for category 3 stocks.
This is the ratio of the mean length (𝐿y−1 ) in the observed catch that
is above the length of first capture relative to the target reference
length (mean length/target reference length). The target reference
length is 𝐿fm = 0.75 Lc + 0.25 Linf, where Lc is defined as length at
50% of modal abundance

## Usage

``` r
fishing_pressure_proxy(len_data, Linf, Lc, assessment_year, lag = 1)
```

## Arguments

- len_data:

  A data frame containing length frequencies. Requires the columns
  "year", "length", and "n"

- Linf:

  L-infinity from the Von Bertalanffy equation

- Lc:

  The length at first capture (defined as the length at 50% of modal
  abundance)

- assessment_year:

  The current assessment year

- lag:

  Number of years from the assessment year for the length distributions.
  Normally equal to 1, so that measurements are taken from the most
  recent complete year. If survey data is used, the most recent survey
  may have occurred in the assessment year, therefore lag should equal
  0.

## Value

A list containing the length at first capture, Linf, mean length above
Lc in previous year, target reference length, and the fishing pressure
proxy
