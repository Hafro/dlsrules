# Advice history rows

The rows of this assessment for the advice history table: the advised
catch (rounded) of the prognosis for each fishing year it holds for,
starting with the fishing year that starts in the assessment year.

## Usage

``` r
advice_hist_rows(
  prognosis,
  assessment_year,
  n_years = 1,
  basis_en = "Domestic advice",
  basis_is = "Innlend ráðgjöf"
)
```

## Arguments

- prognosis:

  The prognosis from
  [`rfb_advice()`](https://hafro.github.io/dlsrules/reference/rfb_advice.md)
  or
  [`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
  (a data frame with the columns `component` and `value`).

- assessment_year:

  The assessment year.

- n_years:

  Number of fishing years the advice holds for (2 for a biennial
  advice).

- basis_en, basis_is:

  Basis of the advice in English and Icelandic.

## Value

A data frame with the columns `assessment_year`, `advice_period` (e.g.
"2025/2026"), `advice`, `advice_basis.en` and `advice_basis.is`.
