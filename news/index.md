# Changelog

## dlsrules 2026-10-09

### rfb rounding option (October 2026, branch `iag`)

- [`rfb_rule()`](https://hafro.github.io/dlsrules/reference/rfb_rule.md)
  and
  [`rfb_advice()`](https://hafro.github.io/dlsrules/reference/rfb_advice.md)
  take `digits`, the rounding of the shown components (index A and B,
  ratio, last index value, I_trigger and I_loss, advice change). The
  advice is computed from unrounded values as before. The defaults are
  the old ones; `c(index = 4, ratio = 4, index_value = 3, change = 2)`
  reproduces the sea urchin `rfb_rule_round()` table (191-urx), whose
  relative CPUE index is near 1.

AI use: Claude (Anthropic) wrote this option, its test and this entry
(12 October 2026); nobody has reviewed it yet.

### Harvest rate x index rule of the shrimp stocks (October 2026, branch `iag`)

- New
  [`hr_index_advice()`](https://hafro.github.io/dlsrules/reference/hr_index_advice.md):
  advice = HR proxy x latest survey index, with a biomass safeguard at
  I_trigger and no precautionary multiplier, the rule of the Icelandic
  shrimp stocks
  ([`chr_advice()`](https://hafro.github.io/dlsrules/reference/chr_advice.md)
  applies the K-based multiplier and stops when K \< 0.32). Options
  reproduce the old scripts: binary or unapplied safeguard
  (`safeguard`), safeguard before or after the stability clause
  (`safeguard_step`), the stability clause’s limits, threshold and
  direction (`stability_limits`, `stability_threshold`,
  `stability_when`), setting the advice to the limit (`stability_set`),
  and the old advice-change formula (`change = "new"`). With the
  Arnarfjordur options it gives the published 2026 advice (248.082 t)
  and the old script’s result for any index and previous advice (tests).
- `hr_index_advice(apply_safeguard = FALSE)`: b is computed as
  `safeguard` says and shown in the table, but not applied (the old
  Isafjardardjup and Snaefellsnes scripts: binary b, not applied). With
  `change = "previous"` the change from a previous advice of 0 is `NA`
  (undefined; the old Isafjardardjup table), not `Inf`/`NaN`. With the
  Isafjardardjup options the old script’s lines give 0 t in 2026 (0.5 x
  267 = 133.5 t, capped at 1.2 x 0 by the leftover clause), the same as
  the published rule.
- Correction (lead, October 2026): the published inshore shrimp rule has
  no stability clause. Arnarfjordur and Isafjardardjup use A = I x HR x
  b with the binary safeguard (`safeguard = "binary"`, no
  `stability_limits`), which reproduces their published advice
  (Isafjardardjup 2021-2026 exactly, Arnarfjordur 2016-2026 within later
  index revisions). The clause and `apply_safeguard = FALSE` options
  describe leftover lines of the old scripts and are kept for comparison
  only.

AI use: Claude (Anthropic) wrote this function, its tests and this entry
(12 October 2026); nobody has reviewed them yet.

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
