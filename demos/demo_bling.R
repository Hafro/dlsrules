## -----------------------------------------------------------------------------
##
## DLS runner bling
##
## -----------------------------------------------------------------------------

## Libraries
library(tidyverse)
library(mar)
#library(dlsrules)
library(tidypax)
library(mfdb)
# library(fitdistrplus)

for (i in dir('R')) source(file.path('R', i))

## Open mar connection
mar <- connect_mar()

## -----------------------------------------------------------------------------

## Set some parameters
tyr <- lubridate::year(Sys.Date())
lastyear <- tyr - 1

tegund_nr <- 7

## tac
tac <- 259
tac_lastyear <- 334

# vonb K taken from Muggur's presentation (2021/07 WKILIFE Subgroup)
tegund_k <- 0.1

## Bin width for length distribution
lbinwidth <- 1

## Whether or not to apply the precautionary buffer - this is only relevant for the old 2/3 rule
# LAst applied in 2019 for blue ling
apply_precuationary_buffer <- TRUE

## -----------------------------------------------------------------------------
## Indices
## -----------------------------------------------------------------------------

## Biomass index
idata <- si_stations(mar) %>%
  filter(nvl(tow_number,0) %in% 0:75,
         gear_id %in% 77:78,
         sampling_type == 35) %>%
  si_by_length(species = tegund_nr) %>%
  si_add_strata() %>%
  filter(stratification == 'new_strata') %>%
  si_by_strata() %>%
  si_by_year() %>%
  filter(year != 2011,
         year > 1999) %>%
  select(year, index = b) %>%
  arrange(year) %>%
  collect(n = Inf)

## Check two over three
print(calc_ratio(idata))
print(mean(tail(idata$index, n = 2)))

## Iloss - using lowest value, not the second lowest
Iloss <- min(idata$index) #sort(idata$index, decreasing = FALSE)[1]

## Itrigger equals 1.4 * Iloss
Itrigger <- 1.4*Iloss

## -----------------------------------------------------------------------------
## Length distributsions
## -----------------------------------------------------------------------------

## Commercial length distribution by year
ldist.year <-
  ldist_by_year(mar, sampling_type = c(1,2,8), species_nr = tegund_nr) %>%
  filter(mfdb_gear_code %in% c('BMT', 'LLN'),
         year > 1975) %>% ## Removing measurements from 1939 (?)
  group_by(year, length) %>%
  summarise(n = sum(n)) %>%
  collect(n = Inf)

## Aggregated over years
ldist.all <-
  ldist.year %>%
  group_by(length) %>%
  summarise(n = sum(n))

## -----------------------------------------------------------------------------
## L-Infinity
# Use max length to start
linf <- max(ldist.all$length)

## Other possible definitions of L-infinity:
q99 <- quantile(rep(ldist.all$length, ldist.all$n), 0.99) # 99th percentile
q95 <- quantile(rep(ldist.all$length, ldist.all$n), 0.95) # 95th percentile
fishbase_linf <- 160

## Von B
mdb <- mfdb('Iceland',db_params=list(host='mfdb.hafro.is'))

mfdb_dplyr_sample(mdb) %>%
  dplyr::filter(species %in% c('BLI'), data_source=='iceland-aldist',
                sampling_type %in% c('SEA')) %>%
  dplyr::collect(n=Inf) -> fff_K

mfdb_disconnect(mdb)

age.data.bli <- filter(fff_K, !is.na(age))
#weight.data.bli <- filter(age.data.bli,!is.na(weight))
bli.vonB.par <- nls(length~Linf*(1-exp(-K*(age-t0))), data=age.data.bli, start=list(Linf=120, K=0.1, t0=0))

vonb_linf <- coef(bli.vonB.par)[['Linf']]
print(paste('vonb K = ', coef(bli.vonB.par)[['K']]))

plot(age.data.bli$age, age.data.bli$length)
predict(bli.vonB.par, newdata = data.frame(age = seq(0,20,by = 0.1))) -> preds
lines(seq(0,20,by = 0.1), preds, col = "red")

## Can also try:
# linf <- max(ldist.all$length) / 0.95

## Calculate ratio of mean length above Lc in past year to target reference length
len_ratio <- fishing_pressure_proxy(ldist.year, Linf = linf, assessment_year = tyr)

## -----------------------------------------------------------------------------

## Run rules:

## Advice for current assessment based on new rule
rfb_rule(data = idata,
         prev_tac = tac,
         Itrigger = Itrigger,
         stock_k = tegund_k,
         len_data = ldist.year,
         Linf = linf,
         assessment_year = tyr)

## Advice for current assessment based on old rule
two_over_three(data = idata,
               prev_tac = tac,
               pre_buffer = apply_precuationary_buffer)


## Check advice based on old rule for last year
#two_over_three(data = idata %>% filter(year != 2021),
#               prev_tac = tac_lastyear,
#               pre_buffer = apply_precuationary_buffer)
#print(tac)

## -----------------------------------------------------------------------------

## ------------------------------------------------------------------------------
## Sensitivity analyses for L-infinity
## -----------------------------------------------------------------------------

test_linf <- 100:200

##" Loop over
res <- lapply(test_linf, function(x){
  ## Advice for current assessment based on new rule
  tmp <- rfb_rule(data = idata,
                  prev_tac = tac,
                  Itrigger = Itrigger,
                  stock_k = tegund_k,
                  len_data = ldist.year,
                  Linf = x,
                  assessment_year = tyr)
  tmp$lf <- x
  return(tmp)
})
out <- do.call("rbind", res)

out2 <-
  out %>% filter(Component == 'final_advice') %>% distinct()

linf_df <-
  tibble(TAC = c(c(min(out2$value), filter(out2, lf == linf)$value),
                   c(min(out2$value), filter(out2, lf == round(q99,0))$value),
                   c(min(out2$value), filter(out2, lf == round(q95,0))$value),
                   c(min(out2$value), filter(out2, lf == round(fishbase_linf,0))$value)),
         x = c(linf, linf, q99, q99, q95, q95, fishbase_linf, fishbase_linf),
         LInf_measure = rep(c('Max_Len', 'Q99_Len', 'Q95_Len', 'Fishbase_LInf'), each = 2))

## Plot sensitivity of tac to linf
out2 %>%
  rename(L_Infinity = lf, TAC = value) %>%
  ggplot(aes(L_Infinity, TAC)) +
  geom_line(size = 1.5) +
  geom_line(aes(x, TAC,  col = LInf_measure), data = linf_df, size = 1.5)


## Check output for each linf est.
## Max length
filter(out, LInfinity == linf)
## Q99
filter(out, LInfinity == q99)
## Q95
filter(out, LInfinity == q95)
## Von b
out[out$LInfinity == as.integer(vonb_linf),]




