# One index series from a table of survey indices

Picks one index out of a long table of survey indices and returns it in
the form the rules take (columns `year` and `index`).

## Usage

``` r
index_series(survey_index, name, year_end = NULL, value = "b")
```

## Arguments

- survey_index:

  A data frame of survey indices with a column `index` naming the
  series, a column `year` and the value column.

- name:

  The name of the series (value of the `index` column).

- year_end:

  Last year to keep (e.g. the assessment year), or NULL for all years.

- value:

  Name of the value column (`"b"` for biomass, `"n"` for abundance).

## Value

A tibble with the columns `year` and `index`.
