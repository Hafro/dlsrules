# Reference point table of the rfb rule

The reference points of the rfb rule as a one-row table, with I_loss
(`I_lim`) and I_trigger rounded to whole units of the index.

## Usage

``` r
rfb_ref_points_table(ref_points)
```

## Arguments

- ref_points:

  A list with `I_lim`, `I_trigger`, `F_msy_proxy`, `Lc`, `Linf` and `K`
  (see
  [`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md)).
  L_F=M (`trl`) is `target_reference_length` if the list has it,
  otherwise computed from `Lc` and `Linf`.

## Value

A tibble with the columns `I_lim`, `I_trigger`, `F_msy_proxy`, `Lc`,
`Linf`, `K` and `trl`.
