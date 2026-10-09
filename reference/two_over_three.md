# Two over three rule

Calculates the advised catch based on the category 3 two-over-three
rule. The uncertainty cap is accounted for and the precautionary buffer
is optional.

## Usage

``` r
two_over_three(data, prev_tac, pre_buffer = FALSE)
```

## Arguments

- data:

  A data-frame containing the columns 'year' and 'index'

- prev_tac:

  The catch advice for the previous advisory year

- pre_buffer:

  If TRUE the precuationary buffer (-20%) will be applied. If FALSE, it
  won't.

## Value

A dataframe with the advice for the current year. 'final_advice' is the
advice after the uncertainty cap and precautionary buffer are
considered, the 'initial_advice' and 'int_advice' are the values prior
to each of these steps respectively.
