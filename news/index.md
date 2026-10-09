# Changelog

## dlsrules 2026-10-09

Helpers shared by the MFRI category 3 stock assessments (rfb: 13-cas,
14-mon, 24-lem, 25-wit, 26-meg, 27-dab, 60-norway-redfish; chr: 04-whg),
which had their own copies of them. The stock repositories call them
with their stock-specific choices as arguments; on the same data they
give the same numbers as the copies they replace.

### New functions

- Length distributions:
  [`catch_ldist()`](https://hafro.github.io/dlsrules/reference/catch_ldist.md)
  reads the catch length distributions for the rule from a pax database
  (lengths rounded, counts not raised a second time; pax is in Suggests
  and only this function needs it);
  [`rule_ldist()`](https://hafro.github.io/dlsrules/reference/rule_ldist.md)
  selects the gears, years and lengths of the rule from a collected
  distribution and can add other distributions (e.g. survey lengths in
  years without catch samples).
- Fishing pressure:
  [`mean_length_above()`](https://hafro.github.io/dlsrules/reference/mean_length_above.md)
  (L_mean above L_c),
  [`fproxy_series()`](https://hafro.github.io/dlsrules/reference/fproxy_series.md)
  (f and the F proxy L_F=M / L_mean by year, with the years as
  arguments),
  [`harvest_rate_proxy()`](https://hafro.github.io/dlsrules/reference/harvest_rate_proxy.md)
  (the chr harvest rate proxy) and
  [`linf_from_catch()`](https://hafro.github.io/dlsrules/reference/linf_from_catch.md).
- I_loss and I_trigger:
  [`index_series()`](https://hafro.github.io/dlsrules/reference/index_series.md),
  [`calc_iloss()`](https://hafro.github.io/dlsrules/reference/calc_iloss.md)
  with the method `"min"`, `"second_min"`, `"mean"` or `"fixed"`, and
  [`ref_points_iloss()`](https://hafro.github.io/dlsrules/reference/ref_points_iloss.md).
- History and tables:
  [`assessment_summary()`](https://hafro.github.io/dlsrules/reference/assessment_summary.md)
  (log-normal or normal intervals),
  [`advice_hist_rows()`](https://hafro.github.io/dlsrules/reference/advice_hist_rows.md)
  and
  [`rfb_ref_points_table()`](https://hafro.github.io/dlsrules/reference/rfb_ref_points_table.md).
- Rule wrappers:
  [`rfb_advice()`](https://hafro.github.io/dlsrules/reference/rfb_advice.md)
  and
  [`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
  cut the index at the assessment year, run
  [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
  /
  [`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
  and return the prognosis with lower-case component names and the
  assessment year.

### Other changes

- [`calc_Itrigger()`](https://hafro.github.io/dlsrules/reference/calc_Itrigger.md)
  gains `factor` (default 1.4, as before).
- [`target_reference_length()`](https://hafro.github.io/dlsrules/reference/target_reference_length.md)
  (L_F=M) has its own help page again.
- dplyr is now imported; tests (testthat) added.

## dlsrules 2022-05-31 (2bbde3c, September 2026)

- [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
  stops when K \>= 0.32 and computes the target reference length from
  `Linf` and `Lc` (a `target_reference_length` element of `ref_points`
  is no longer used);
  [`fproxy_rule()`](https://hafro.github.io/dlsrules/reference/fproxy_rule.md)
  stops when K \< 0.32 or K \>= 0.45;
  [`calc_ratio()`](https://hafro.github.io/dlsrules/reference/calc_ratio.md)
  needs five years of index;
  [`multiplier_lookup()`](https://hafro.github.io/dlsrules/reference/multiplier_lookup.md)
  stops when K \>= 0.45.
