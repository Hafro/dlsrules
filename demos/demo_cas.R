## -----------------------------------------------------------------------------
##
## DLS runner CAS
##
## -----------------------------------------------------------------------------

## Libraries
library(tidyverse)
library(mar)
library(dlsrules)
library(tidypax)
#library(fitdistrplus)

## Open mar connection
mar <- connect_mar()

## -----------------------------------------------------------------------------

## Set some parameters
tyr <- lubridate::year(Sys.Date())
lastyear <- tyr - 1

tegund_nr <- 13

## tac
tac <- 377
tac_lastyear <- 314

## F-proxy
prev_fproxy <- 0.131

# vonb K taken from Muggur's presentation (2021/07 WKILIFE Subgroup)
tegund_k <- 0.1

## Bin width for length distribution
lbinwidth <- 1

## Whether or not to apply the precautionary buffer - this is only relevant for the old 2/3 rule
apply_precuationary_buffer <- FALSE

## -----------------------------------------------------------------------------
## Indices and landings
## -----------------------------------------------------------------------------

## Biomass index
if (TRUE){
  
  idata <-
    si_stations(mar) %>%
    filter(sampling_type == 30, nvl(tow_number,0) %in% 0:35) %>%
    si_by_length(species = tegund_nr) %>%
    si_add_strata() %>%
    filter(stratification == 'new_strata') %>%
    si_by_strata() %>%
    si_by_year() %>%
    select(year, index = b) %>%
    arrange(year) %>%
    collect(n = Inf)
  
  
}else{
  
  load("/net/hafkaldi/export/u2/reikn/R/SurveyWork/SMH/Allaggrsmhindex.rdata")
  idata <-
    Allaggrsmhindex %>%
    filter(species == tegund_nr,
           svaedi == 'Heild',
           fixed == 0,
           skipShallow == 0,
           ar > 1999) %>%
    rename(year = ar) %>%
    group_by(year) %>%
    summarise(index = sum(ifelse(lengd == 10,bio.staerri,0)))
  
}

## Landings
landings <- landadur_afli(mar) %>%
  filter(tegund_nr == local(tegund_nr),
         ices_svaedi %like% '5a%',
         ar > 1984) %>%
  group_by(ar) %>%
  summarise(catch = sum(magn_oslaegt)/1e3) %>%
  rename(year = ar) %>%
  arrange(year) %>%
  collect(n=Inf)

## Merge and calculate harvest rate
alldata <-
  idata %>%
  left_join(landings, by = 'year') %>%
  mutate(hr = catch/index)


## Check two over three
print(calc_ratio(idata))
print(mean(tail(idata$index, n = 2)))

## Iloss - using the lowest index value for CAS
Iloss <- min(idata$index) #sort(idata$index, decreasing = FALSE)[1]

## Itrigger equals 1.4 * Iloss
Itrigger <- 1.4*Iloss

## -----------------------------------------------------------------------------
## Length distributsions
## -----------------------------------------------------------------------------

## Commercial length distribution by year
ldist.year <-
  ldist_by_year(mar, sampling_type = c(1,2,8), species_nr = tegund_nr) %>%
  filter(mfdb_gear_code %in% c('BMT', 'LLN')) %>%
  filter(year > 1975) %>%
  group_by(year, length) %>%
  summarise(n = sum(n)) %>%
  collect(n = Inf)

## Aggregated over years
ldist.all <-
  ldist.year %>%
  group_by(length) %>%
  summarise(n = sum(n))

## Calculations based on raw data (ie no model)
## 1. modal abundance
## 2. length of modal abundance
## 3. 50% modal abundance

ma_ind <- which.max(ldist.all$n)
modal_abun <- ldist.all$n[ma_ind]
modal_abun_len <- ldist.all$length[ma_ind] ## Same as calcmode
modal_abun50 <- modal_abun*0.5

## Length at first capture equals the length at 50% modal abun
## Find first length class where n > modal_abun50
Lc <- min(ldist.all$length[ldist.all$n > modal_abun50])

## OR:
## Find first length class where the difference between n and modal_abun50 is minimised
#Lc_ind <- which.min(abs(ldist.all$n[ldist.all$length < modal_abun_len] - modal_abun50))
#Lc <- ldist.all$length[Lc_ind]

## Method 2: following Elvar, fit a normal dist
# ldist_norm <- fitdist(rep(ldist.all$length, ldist.all$n), 'norm')
# ldist_mean <- ldist_norm$estimate['mean']
# ldist_sd <- ldist_norm$estimate['sd']

## Mean length above Lc per year
meanL.year <-
  ldist.year %>%
  filter(length > Lc) %>%
  group_by(year) %>%
  summarise(L = sum(length*n)/sum(n))

## Mean length of last year (2021)
meanL <- meanL.year[meanL.year$year == lastyear, 'L']$L

## -----------------------------------------------------------------------------
## Try different Linfs

## TRY FITTING VON B IF AGE DATA IS AVAILABLE
mdb <- mfdb('Iceland',db_params=list(host='mfdb.hafro.is'))

mfdb_dplyr_sample(mdb) %>%
  dplyr::filter(species %in% c('CAS'), data_source=='iceland-aldist',
                sampling_type %in% c('IGFS')) %>%
  dplyr::collect(n=Inf) -> fff_K

mfdb_disconnect(mdb)

age.data.cas <- filter(fff_K,!is.na(age))
weight.data.cas <- filter(age.data.cas,!is.na(weight))

cas.vonB.par <- nls(length~Linf*(1-exp(-K*(age-t0))), data=weight.data.cas, start=list(Linf=120, K=0.3, t0=-1))
#confint(cas.vonB.par)

plot(weight.data.cas$age, weight.data.cas$length)
predict(cas.vonB.par, newdata = data.frame(age = seq(0,20,by = 0.1))) -> preds
lines(seq(0,20,by = 0.1), preds, col = "red")

## Default linf
linf <- coef(cas.vonB.par)[['Linf']]

## Other options:
# 95 and 99 percentile of length distribution
q99 <- quantile(rep(ldist.all$length, ldist.all$n), 0.99)
q95 <- quantile(rep(ldist.all$length, ldist.all$n), 0.95)
## Compare with max length
maxlen <- max(ldist.all$length)

## Can also try:
# linf <- max(ldist.all$length) / 0.95

## -----------------------------------------------------------------------------
## CALCULATE A TARGET FPROXY BASED ON LENGTH DISTS
# THIS MAY NOT WORK IF LINF IS VERY LARGE BECAUSE IT CAN RESULT IN A 
# TARGET REFERENCE LENGTH THAT IS LARGER THAN ANY ANNUAL MEAN LENGTH
# EG USING VONB LINF FOR CAS...

## Calculate MSY proxy reference catch length,
trl <- target_reference_length(Lc, linf)

## Identify all years where mean catch length above Lc is > target reference length
year_ind <- which(meanL.year$L > trl)

## New fproxy is the harvest rates from year_ind averaged
fproxy <- mean(alldata$hr[year_ind])

## -----------------------------------------------------------------------------

## Calculate ratio of mean length above Lc in past year to target reference length
len_ratio <- calc_f(meanL = meanL, Lc = Lc, Linf = linf)

## -----------------------------------------------------------------------------

## Run rules:

## FIRST DOUBLE CHECK LAST YEAR ADVICE
(idata[idata$year == lastyear, 'index']$index * prev_fproxy) %>% uncertainty_cap(tac_lastyear)

## Advice based on old rule for current assessment
(idata[idata$year == tyr, 'index']$index * prev_fproxy) %>% uncertainty_cap(tac)

## Same with presuationary buffer, as F is greater than Fproxy?
(idata[idata$year == tyr, 'index']$index * prev_fproxy) %>% uncertainty_cap(tac) %>% precautionary_buffer()

## NEW RULES
## Advice for current assessment based on new rule and fproxy from ices guidelines
fproxy_rule(data = idata,
            prev_tac = tac,
            fproxy = fproxy,
            Itrigger = Itrigger,
            stock_k = tegund_k)

## Advice for current assessment based on new rule and existing fproxy
fproxy_rule(data = idata,
            prev_tac = tac,
            fproxy = prev_fproxy,
            Itrigger = Itrigger,
            stock_k = tegund_k)

## Run rules:

## Advice for current assessment based on new rule
rfb_rule(data = idata,
         prev_tac = tac,
         Itrigger = Itrigger,
         stock_k = tegund_k,
         len_ratio = len_ratio)

## Advice for current assessment based on old rule
two_over_three(data = idata,
               prev_tac = tac,
               pre_buffer = apply_precuationary_buffer)



## -----------------------------------------------------------------------------
## F-proxy plots
## -----------------------------------------------------------------------------

#fproxy_plot <-
alldata %>%
  filter(year != tyr) %>%
  mutate(harvest_rate = hr) %>%
  ggplot(aes(year, harvest_rate)) +
  geom_line() +
  geom_hline(yintercept = fproxy, col = 'red') +
  # geom_hline(yintercept = prev_fproxy, col = 'blue') +
  geom_point(aes(year, hr), data = alldata[year_ind,], col = 'red')

#ldist_plot <-
meanL.year %>%
  ggplot(aes(year, L)) +
  geom_line() +
  geom_hline(yintercept = trl, col = 'blue', lty = 'dashed') +
  geom_point(aes(year, L), data = meanL.year[year_ind,], col = 'blue')



## Labels for legend
lenrps <- tibble(rp = c(modal_abun_len, Lc, linf, trl),
                 Len_stat = c('Modal_len', 'Len_1st cap.', 'Linf', 'Target_ref_Len'))

## Length distribution plot
cols <- c('Modal_len' = 'red', 'Len_cap' = 'orange', 'linf' = 'blue', 'tar_ref_len' = 'green')
ldist.all %>%
  mutate(modal_abun_len = modal_abun_len,
         Lc = Lc,
         linf = linf,
         tar_ref_len = target_reference_length(Lc, linf)) %>%
  ggplot(aes(length, n)) +
  geom_col(width = 1) +
  geom_vline(aes(xintercept = modal_abun_len, col = 'Modal_len'), size = 1, key_glyph = "path") +
  geom_vline(aes(xintercept = Lc, col = 'Len_cap'), size = 1, lty = 'dashed', key_glyph = "path") +
  geom_vline(aes(xintercept = linf, col = 'linf'), size = 1, key_glyph = "path") +
  geom_vline(aes(xintercept = tar_ref_len, col = 'tar_ref_len'), size = 2, key_glyph = "path") +
  scale_colour_manual(name = 'Length stats', values = cols)


## Biomass safeguard plot
idata %>%
  ggplot(aes(year, index)) +
  geom_line() +
  geom_point(data = idata %>% filter(idata$index == Iloss), col = "red", size = 4) +
  geom_hline(yintercept = Itrigger, col = "red", lty = "solid", size = 1) +
  geom_point(data = idata %>% filter(year == tyr), col = "black", pch = 3, size = 2)

## ------------------------------------------------------------------------------
## Sensitivity analyses for L-infinity
## -----------------------------------------------------------------------------

test_linf <- 50:200

##" Loop over
res <- lapply(test_linf, function(x){
  ## Advice for current assessment based on new rule
  tmp <- rfb_rule(data = idata,
                  prev_tac = tac,
                  Itrigger = Itrigger,
                  stock_k = tegund_k,
                  len_ratio = calc_f(meanL = meanL, Lc = Lc, Linf = x))
  tmp$linf <- x
  return(tmp)
})
out <- do.call("rbind", res)

out2 <-
  out %>% filter(Component == 'final_advice') %>% distinct()

## Plot sensitivity of tac to linf
out2 %>%
  ggplot(aes(linf, value)) +
  geom_line(size = 1.5) +
  geom_line(aes(linf, value),
            data = tibble(value = c(min(out2$value), filter(out2, linf == maxlen)$value), linf = c(maxlen, maxlen)), col = 'red', size = 1.5) +
  geom_line(aes(linf, value),
            data = tibble(value = c(min(out2$value), filter(out2, linf == round(q99,0))$value), linf = c(q99, q99)), col = 'orange', size = 1.5) +
  geom_line(aes(linf, value),
            data = tibble(value = c(min(out2$value), filter(out2, linf == round(q95,0))$value), linf = c(q95, q95)), col = 'yellow', size = 1.5) +
  geom_line(aes(linf, value),
            data = tibble(value = c(min(out2$value), filter(out2, linf == round(160,0))$value), linf = c(round(linf,0), round(linf,0))), col = 'green', size = 1.5)


## Check output for each linf est.
## Max length
filter(out, linf == maxlen)
## Q99
filter(out, linf == q99)
## Q95
filter(out, linf == q95)
## Von b
out[out$linf == as.integer(linf),]






