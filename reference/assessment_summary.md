# Assessment summary rows of a category 3 stock

The rows of this assessment for the assessment history table (one row
per year): the biomass index as SSB, optionally a recruitment index, the
fishing pressure proxy as F and/or catch / biomass index as the harvest
rate, each with 95% intervals where they have a CV. The column names are
those of the MFRI assessment history template (`median_SSB`, `low_SSB`,
`high_SSB`, `median_recruitment`, ..., `median_F`, `median_HR`).

The intervals are log-normal, x exp(-/+ 1.96 CV), unless `"normal"` is
asked for, x (1 -/+ 1.96 CV), which can be negative.

## Usage

``` r
assessment_summary(
  survey_index,
  ssb_index,
  rec_index = NULL,
  fishing_pressure = NULL,
  landings = NULL,
  species,
  assessment_year,
  ssb_ci = "lognormal",
  rec_ci = "lognormal",
  landings_year_end = assessment_year - 1
)
```

## Arguments

- survey_index:

  A long data frame of survey indices with the columns `index` (series
  name), `year`, `b`, `b_cv` (biomass and its CV), `n` and `n_cv`
  (abundance and its CV).

- ssb_index:

  Name of the biomass index shown as SSB (biomass `b`).

- rec_index:

  Name of the index shown as recruitment (abundance `n`), or NULL for
  none.

- fishing_pressure:

  NULL, or a data frame with the columns `year` and `F_proxy` (e.g. from
  [`fproxy_series()`](https://hafro.github.io/dlsrules/reference/fproxy_series.md),
  with the years already chosen), shown as F.

- landings:

  NULL, or a data frame with the columns `year` and `landings` (in the
  units of the index). If given, landings / SSB index is shown as the
  harvest rate (`median_HR`) up to `landings_year_end`.

- species:

  Species number.

- assessment_year:

  The assessment year: years after it are left out.

- ssb_ci, rec_ci:

  `"lognormal"` or `"normal"` 95% intervals.

- landings_year_end:

  Last year of the harvest rate (the catches of the assessment year are
  not complete).

## Value

A tibble with the columns `year`, `median_SSB`, `low_SSB`, `high_SSB`,
(`median_recruitment`, `low_recruitment`, `high_recruitment`,)
(`median_F`,) (`median_HR`,) `species` and `assessment_year`, one row
per year of the SSB index.
