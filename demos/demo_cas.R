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
# library(fitdistrplus)

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
idata <- si_stations(mar) %>%
  filter(sampling_type == 30, nvl(tow_number,0) %in% 0:35) %>%
  si_by_length(species = tegund_nr) %>%
  si_add_strata() %>%
  filter(stratification == 'new_strata') %>%
  si_by_strata() %>%
  si_by_year() %>%
  select(year, index = b) %>%
  arrange(year) %>%
  collect(n = Inf)


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

## L infinity assumed to be maximum observed length
linf <- max(ldist.all$length)
## Can also try:
# linf <- max(ldist.all$length) / 0.95

## Calculate MSY proxy reference catch length
trl <- target_reference_length(Lc, linf)

## Identify all years where mean catch length above Lc is > target reference length
year_ind <- which(meanL.year$L > trl)

## New fproxy is the harvest rates from year_ind averaged
fproxy <- mean(alldata$hr[year_ind])

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







