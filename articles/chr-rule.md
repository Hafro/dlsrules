# The chr rule

The constant harvest rate (chr) rule (ICES 2025, method 2.2) is for
category 3 stocks with medium growth (0.32 ≤ K \< 0.45). The advice is
the last index value times a harvest rate:

``` math
A_{y+1} = I_{y} \times F_{proxy} \times b \times m
```

- $`F_{proxy}`$: the harvest rate proxy, the mean of catch / index over
  the reference years in which the mean length of the catch above L_(c)
  is above L_(F=M) (f = L_(mean) / L_(F=M) \> 1);
- $`b`$: the biomass safeguard, as in the rfb rule;
- $`m`$: the multiplier, 0.5 for 0.32 ≤ K \< 0.45;

followed by the stability clause (+20% / −30%, not applied when
$`b < 1`$).

At MFRI the chr rule is used for whiting (04-whg). This vignette follows
04-whg’s pipeline on simulated data; the numbers belong to no stock.

``` r

library(dlsrules)
```

## Simulated data

A biomass index (in the stock repos: the spring survey biomass of
whiting over 40 cm, `smb_b40`, from
[`pax::pax_si_length_index()`](https://rdrr.io/pkg/pax/man/pax_si_index.html)),
the landings, and the catch length distribution by year.

``` r

set.seed(4)
years <- 1985:2026
e <- stats::filter(rnorm(length(years), 0, 0.25), 0.7, method = "recursive")
index <- data.frame(year = years, index = round(8000 * exp(as.numeric(e))))

landings <- data.frame(
  year = 1985:2025,
  landings = round(index$index[1:41] * runif(41, 0.15, 0.45))
)

z <- 0.25 + 0.15 * sin(seq_along(1985:2025) / 5)
ldist <- expand.grid(length = 20:75, year = 1985:2025)
ldist$n <- round(
  3000 * plogis((ldist$length - 38) / 1.5) *
    exp(-z[ldist$year - 1984] * (ldist$length - 38) / 2 * (ldist$length > 38))
)
ldist <- ldist[, c("year", "length", "n")]
```

The index has a value for the assessment year (2026, the spring survey
of the assessment year), the landings and lengths stop the year before.
In a stock repo `ldist` is
[`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
of the `pax_db` target (see
[`vignette("rfb-rule")`](https://hafro.github.io/dlsrules/articles/rfb-rule.md)
for why it does not raise the counts again), and the landings are all
countries’ landings in 5.a in tonnes.

## Harvest rate proxy

L_(inf) for whiting is a high quantile of the lengths in the catch,
because the growth parameters of the stock are not reliable. 04-whg uses
the 99.8% quantile (the largest length was unreasonably high); `p = 1`
gives the largest length.

``` r

assessment_year <- 2026
Lc <- 39
Linf <- linf_from_catch(ldist, p = 0.998)
Linf
#> [1] 75
hr <- harvest_rate_proxy(
  ldist,
  index,
  landings,
  Lc = Lc,
  Linf = Linf,
  hr_years = 1985:(assessment_year - 1)
)
head(hr)
#> # A tibble: 6 × 7
#>    year     L     f index landings    hr used 
#>   <int> <dbl> <dbl> <dbl>    <dbl> <dbl> <lgl>
#> 1  1985  46.7 0.974  8445     3552 0.421 FALSE
#> 2  1986  46.2 0.962  7255     1216 0.168 FALSE
#> 3  1987  45.7 0.952  9336     1528 0.164 FALSE
#> 4  1988  45.3 0.945 10345     4621 0.447 FALSE
#> 5  1989  45.1 0.939 14415     3052 0.212 FALSE
#> 6  1990  44.9 0.935 14353     6153 0.429 FALSE
attr(hr, "hr_proxy")
#> [1] 0.2967323
```

The result has one row per year with length data; `used` marks the
reference years (in `hr_years` and f \> 1). The proxy is the mean of
`hr` over those years, kept as the attribute `hr_proxy`, with L_(c),
L_(inf) and L_(F=M) in the attributes `lc`, `linf` and `lfm` for the
tech report figures.

``` r

hr[hr$used, c("year", "f", "hr")]
#> # A tibble: 14 × 3
#>     year     f    hr
#>    <int> <dbl> <dbl>
#>  1  2001  1.01 0.226
#>  2  2002  1.03 0.339
#>  3  2003  1.05 0.230
#>  4  2004  1.06 0.310
#>  5  2005  1.08 0.290
#>  6  2006  1.09 0.322
#>  7  2007  1.10 0.350
#>  8  2008  1.10 0.214
#>  9  2009  1.09 0.443
#> 10  2010  1.08 0.393
#> 11  2011  1.07 0.233
#> 12  2012  1.05 0.270
#> 13  2013  1.03 0.237
#> 14  2014  1.01 0.298
```

## Reference points and advice

The chr rule needs K (for the multiplier) and I_(trigger). I_(loss) is
computed from the index up to the assessment year:

``` r

ref_points <- ref_points_iloss(
  list(K = 0.38),
  index[index$year <= assessment_year, ],
  method = "min",
  itrigger_factor = 1.4
)
str(ref_points)
#> List of 4
#>  $ K         : num 0.38
#>  $ I_lim     : num 6228
#>  $ I_lim_year: int 2018
#>  $ I_trigger : num 8719
```

[`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
cuts the index at the assessment year, runs
[`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
and returns the components with lower-case names. It is the
`chr_prognosis` target of 04-whg, and feeds
`hafroreports::hr_advice_table_chr()` and
[`advice_hist_rows()`](https://hafro.github.io/dlsrules/reference/advice_hist_rows.md).

``` r

prognosis <- chr_advice(
  index,
  prev_tac = 1320,
  hr_proxy = attr(hr, "hr_proxy"),
  ref_points = ref_points,
  assessment_year = assessment_year
)
#> [1] "'K' is greater than 0.32 therefore apply the CHR rule"
prognosis
#> # A tibble: 12 × 4
#>    component                   value type                     assessment_year
#>    <chr>                       <dbl> <chr>                              <dbl>
#>  1 previous_catch_advice    1320     advice                              2026
#>  2 biomass_index            9775     biomass_index                       2026
#>  3 Fmsy_proxy                  0.297 fishing_pressure_proxy              2026
#>  4 last_index_value         9775     biomass_safeguard                   2026
#>  5 Itrigger                 8719     biomass_safeguard                   2026
#>  6 Iloss                    6228     biomass_safeguard                   2026
#>  7 biomass_safeguard           1     biomass_safeguard                   2026
#>  8 multiplier                  0.5   precautionary_multiplier            2026
#>  9 initial_catch_advice     1450.    advice                              2026
#> 10 stability_clause_applied    0     advice                              2026
#> 11 catch_advice             1450.    advice                              2026
#> 12 advice_change              10     advice                              2026
```

[`multiplier_lookup()`](https://hafro.github.io/dlsrules/reference/multiplier_lookup.md)
prints a reminder that K ≥ 0.32 means the chr rule;
[`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
stops for K \< 0.32 (use the rfb rule) and for K ≥ 0.45.

## Pitfalls

- **Units:** the harvest rate is landings / index, so both must be in
  the same units (tonnes). The proxy is only meaningful for the same
  index as the advice uses.
- **Whose landings:** 04-whg uses all countries’ landings in 5.a, as in
  the harvest rate of its history table. The old `chr_rule.R` used
  Icelandic landings only. Choose deliberately: it changes the proxy.
- **Reference years:** the old 04-whg code wrote `1985:tyr-1`, which in
  R is `1984:(tyr - 1)`. 1984 has no index, so the result was the same;
  write `1985:(assessment_year - 1)`.
- **The index past the assessment year:** the advice uses the last index
  value, so a later year changes it completely.
  [`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
  cuts the index;
  [`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
  does not.
- **I_(trigger):** if `Itrigger` is `NULL`,
  [`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
  uses 1.4 × the lowest index value it is given and says so only with
  [`cat()`](https://rdrr.io/r/base/cat.html). Pass it from
  [`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md).

## AI use

This vignette was drafted with Claude (Anthropic) in October 2026 and
has not yet been checked by a person (MFRI policy on the use of AI). The
data are simulated.
