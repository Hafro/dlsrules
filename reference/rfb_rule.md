# RFB rule for category 3 stocks

Calculates the advised catch based on the category 3 RFB rule.

## Usage

``` r
rfb_rule(ref_points, index_data, len_data, prev_tac, assessment_year, lag = 1)
```

## Arguments

- ref_points:

  A list with the following elements: 'K', 'Linf', 'Lc', 'I_lim',
  'I_trigger'

- index_data:

  The survey index, must contain 'year' and 'index' columns

- len_data:

  A data frame containing length frequencies. Requires the columns
  "year", "length", and "n"

- prev_tac:

  The preceding assessment year's tac

- assessment_year:

  The current assessment year

- lag:

  Number of years from the assessment year for the length distributions.
  Normally equal to 1, so that measurements are taken from the most
  recent complete year. If survey data is used, the most recent survey
  may have occurred in the assessment year, therefore lag should equal
  0.

## Value

A dataframe with the advice for the current year and information used to
reach this value. 'final_advice' is the advice after the biomass
safeguard is considered, the 'initial_advice' is the value prior to this
step.
