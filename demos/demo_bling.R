## -----------------------------------------------------------------------------
##
## DLS runner bling
##
## -----------------------------------------------------------------------------

## Libraries
library(tidyverse)
library(mar)
library(dlsrules)
library(tidypax)
# library(fitdistrplus)

## Open mar connection
con <- connect_mar()

## -----------------------------------------------------------------------------

## Set some parameters
tyr <- lubridate::year(Sys.Date())
lastyear <- tyr - 1

tegund_nr <- 7

## tac
tac <- 334
tac_lastyear <- 406

# vonb K taken from Muggur's presentation (2021/07 WKILIFE Subgroup)
tegund_k <- 0.1

## Bin width for length distribution
lbinwidth <- 1

## Whether or not to apply the precautionary buffer - this is only relevant for the old 2/3 rule
apply_precuationary_buffer <- FALSE

## -----------------------------------------------------------------------------
## Indices
## -----------------------------------------------------------------------------

## Load
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

## Check two over three
print(calc_ratio(idata))
print(mean(tail(idata$index, n = 2)))

## Iloss - using the second lowest index value for blue ling
Iloss <- sort(idata$index, decreasing = FALSE)[2]

## Itrigger equals 1.4 * Iloss
Itrigger <- 1.4*Iloss

## -----------------------------------------------------------------------------
## Length distributsions
## -----------------------------------------------------------------------------

## Commercial length distribution by year
ldist.year <-
  ldist_by_year(con, sampling_type = c(1,2,8), species_nr = tegund_nr) %>%
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

## Calculate ratio of mean length above Lc in past year to target reference length
len_ratio <- calc_f(meanL = meanL, Lc = Lc, Linf = linf)

## -----------------------------------------------------------------------------

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


## Check advice based on old rule for last year
#two_over_three(data = idata %>% filter(year != 2021),
#               prev_tac = tac_lastyear,
#               pre_buffer = apply_precuationary_buffer)
#print(tac)




