# dlsrules 2026-10-09

## Harvest rate x index rule of the shrimp stocks (October 2026, branch `iag`)

* New `hr_index_advice()`: advice = HR proxy x latest survey index, with a
  biomass safeguard at I_trigger and no precautionary multiplier, the rule
  of the Icelandic shrimp stocks (`chr_advice()` applies the K-based
  multiplier and stops when K < 0.32). Options reproduce the old scripts:
  binary or unapplied safeguard (`safeguard`), safeguard before or after the
  stability clause (`safeguard_step`), the stability clause's limits,
  threshold and direction (`stability_limits`, `stability_threshold`,
  `stability_when`), setting the advice to the limit (`stability_set`), and
  the old advice-change formula (`change = "new"`). With the Arnarfjordur
  options it gives the published 2026 advice (248.082 t) and the old
  script's result for any index and previous advice (tests).
* `hr_index_advice(apply_safeguard = FALSE)`: b is computed as `safeguard`
  says and shown in the table, but not applied (the old Isafjardardjup and
  Snaefellsnes scripts: binary b, not applied). With `change = "previous"`
  the change from a previous advice of 0 is `NA` (undefined; the old
  Isafjardardjup table), not `Inf`/`NaN`. With the Isafjardardjup options
  the 2026 advice is 0 t (0.5 x 267 = 133.5 t, capped at 1.2 x 0 by the
  stability clause), as published.

AI use: Claude (Anthropic) wrote this function, its tests and this entry
(12 October 2026); nobody has reviewed them yet.

Helpers shared by the MFRI category 3 stock assessments (rfb: 13-cas, 14-mon,
24-lem, 25-wit, 26-meg, 27-dab, 60-norway-redfish; chr: 04-whg), which had
their own copies of them. The stock repositories call them with their
stock-specific choices as arguments; on the same data they give the same
numbers as the copies they replace.

## New functions

* Length distributions: `catch_ldist()` reads the catch length distributions
  for the rule from a pax database (lengths rounded, counts not raised a
  second time; pax is in Suggests and only this function needs it);
  `rule_ldist()` selects the gears, years and lengths of the rule from a
  collected distribution and can add other distributions (e.g. survey
  lengths in years without catch samples).
* Fishing pressure: `mean_length_above()` (L_mean above L_c),
  `fproxy_series()` (f and the F proxy L_F=M / L_mean by year, with the years
  as arguments), `harvest_rate_proxy()` (the chr harvest rate proxy) and
  `linf_from_catch()`.
* I_loss and I_trigger: `index_series()`, `calc_iloss()` with the method
  `"min"`, `"second_min"`, `"mean"` or `"fixed"`, and `ref_points_iloss()`.
* History and tables: `assessment_summary()` (log-normal or normal
  intervals), `advice_hist_rows()` and `rfb_ref_points_table()`.
* Rule wrappers: `rfb_advice()` and `chr_advice()` cut the index at the
  assessment year, run `rfb_rule()` / `fproxy_rule()` and return the
  prognosis with lower-case component names and the assessment year.

## Other changes

* `calc_Itrigger()` gains `factor` (default 1.4, as before).
* `target_reference_length()` (L_F=M) has its own help page again.
* dplyr is now imported; tests (testthat) added.

# dlsrules 2022-05-31 (2bbde3c, September 2026)

* `rfb_rule()` stops when K >= 0.32 and computes the target reference length
  from `Linf` and `Lc` (a `target_reference_length` element of `ref_points`
  is no longer used); `fproxy_rule()` stops when K < 0.32 or K >= 0.45;
  `calc_ratio()` needs five years of index; `multiplier_lookup()` stops when
  K >= 0.45.
