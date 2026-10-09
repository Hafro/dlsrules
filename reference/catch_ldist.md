# Catch length distributions for the rule

Length distributions of the catch by year and 1 cm length (optionally
also by gear) from a pax database, for the length-based components of
the rfb and chr rules (mean length above L_c, the fishing pressure proxy
and the harvest rate proxy).

The `ldist` table of a pax database built by
[`pax::pax_from_mar()`](https://rdrr.io/pkg/pax/man/pax_from_mar.html)
is already raised to the counted fish, so the lengths are only rounded
here
([`pax::pax_ldist_scale_round()`](https://rdrr.io/pkg/pax/man/pax_ldist.html));
the counts are not raised a second time.

The query runs in the database and only the summed result is collected.
pax is only needed by this function (it is in Suggests); all other
functions of the package take plain data frames.

## Usage

``` r
catch_ldist(
  station,
  ldist,
  gears = NULL,
  year_start = NULL,
  sampling_type = c(1, 2, 8),
  by_gear = FALSE
)
```

## Arguments

- station:

  A `tbl` of the pax `station` table (e.g.
  `dplyr::tbl(pcon, "station")`, or a stock-specific accessor that fills
  in gear codes).

- ldist:

  A `tbl` of the pax `ldist` table, unrounded (e.g.
  `dplyr::tbl(pcon, "ldist")`).

- gears:

  mfdb gear codes to keep, or NULL for all gears.

- year_start:

  First year to keep, or NULL for all years.

- sampling_type:

  Sampling types of the stations (1, 2 and 8 are the commercial samples
  at sea and in port).

- by_gear:

  If TRUE, keep the gear (`mfdb_gear_code`) as a column.

## Value

A tibble with the columns `year`, (`mfdb_gear_code`,) `length` and `n`
(numbers), sorted by these columns. Samples without the species (no
length) are dropped.
