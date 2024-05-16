#' @title Two over three rule
#' @description Calculates the advised catch based on the category 3 two-over-three rule. The uncertainty cap is accounted for and the precautionary buffer is optional.
#'
#' @param data A data-frame containing the columns 'year' and 'index'
#' @param prev_tac The catch advice for the previous advisory year
#' @param pre_buffer If TRUE the precuationary buffer (-20%) will be applied. If FALSE, it won't.
#'
#' @return A dataframe with the advice for the current year. 'final_advice' is the advice after the uncertainty cap and precautionary buffer are considered, the 'initial_advice' and 'int_advice' are the values prior to each of these steps respectively.
#' @export
two_over_three <- function(data,
                           prev_tac,
                           pre_buffer = FALSE){

  if (!all(c('year', 'index') %in% names(data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }

  ## Calculate the ratio
  ratio <- calc_ratio(data, num = 2, den = 3)

  ## Uncertainty cap - bounds based on previous catch advice
  uc.up <- prev_tac * 1.2
  uc.down <- prev_tac * 0.8

  initial_tac <- ratio['ratio', 'value'] * prev_tac
  int_tac <- max(uc.down, min(uc.up, initial_tac))

  ## Precautionary buffer
  pb <- ifelse(pre_buffer, 0.8, 1)
  tac <- int_tac*pb

  ## Output
  out <- rbind(data.frame(Component = 'previous_advice',
                          value = prev_tac),
               ratio,
               data.frame(Component = c('initial_advice',
                                        'uncertainty_cap_applied',
                                        'int_advice',
                                        'precautionary_buffer_applied',
                                        'final_advice',
                                        'advice_change'),
                          value = c(initial_tac,
                                    ifelse(initial_tac == int_tac, 0, 1),
                                    int_tac,
                                    ifelse(int_tac == tac, 0, 1),
                                    tac,
                                    round((tac-prev_tac)/prev_tac*100, 0))))

  return(tibble::as_tibble(out))
}


#' @title RFB rule for category 3 stocks
#' @description Calculates the advised catch based on the category 3 RFB rule.
#'
#' @param data A data-frame containing the columns 'year' and 'index'
#' @param prev_tac The catch advice for the previous advisory year
#' @param Itrigger Itrigger which is defined as 1.4*Iloss. Generally, Iloss is defined as the lowest observed index value (this is assumed if Itrigger is NULL)
#' @param stock_k The growth parameter 'K'
#' @param len_data A data frame containing length frequencies. Requires the columns "year", "length", and "n"
#' @param Linf L-infinity from the Von Bertalanffy equation
#' @param assessment_year The current assessment year
#'
#' @return A dataframe with the advice for the current year and information used to reach this value. 'final_advice' is the advice after the biomass safeguard is considered, the 'initial_advice' is the value prior to this step.
#' @export
rfb_rule <- function(data,
                     prev_tac,
                     Itrigger = NULL,
                     stock_k,
                     len_data,
                     Linf,
                     assessment_year){

  if (!all(c('year', 'index') %in% names(data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }

  ## Get current indice
  data <- data[order(data$year, decreasing = TRUE),]
  Inow <- data$index[1]

  ## If Itrigger not specified, assume is lowest value
  if (is.null(Itrigger)){
    Itrigger <- 1.4*min(data$index, na.rm = TRUE)
    cat('Assuming Iloss is equal to the lowest observed index value of ', Itrigger/1.4)
  }

  ## Two over three
  ratio <- calc_ratio(data, num = 2, den = 3)

  ## Fishing pressure proxy
  fpp <- fishing_pressure_proxy(len_data, Linf, assessment_year)

  ## Biomass safeguard
  bsg <- biomass_safeguard(Inow = Inow, Itrigger = Itrigger)

  ## Multiplier based on stock growth
  imult <- multiplier_lookup(stock_k)

  ## Calculate prelininary advice
  initial_tac <- prev_tac * ratio['ratio', 'value'] * fpp$fpp * bsg * imult

  ## Apply stability clause for final tac
  tac <- stability_clause(tac = initial_tac,
                          prev_tac = prev_tac,
                          bsg = bsg)

  ## Gather output
  out <-
    data.frame(Component =
                 c('previous_catch_advice',
                   'index_A', 'index_B', 'index_ratio',                          ## Stock biomass trend
                   'mean_catch_length', 'msy_proxy_length', 'fpp_ratio',         ## Fishing pressure proxy
                   'last_index_value', 'Itrigger', 'Iloss', 'biomass_safeguard', ## Biomass safeguard
                   'multiplier',                                                 ## Precautionary multiplier
                   'initial_catch_advice',
                   'stability_clause_applied',
                   'catch_advice',
                   'advice_change'),
               value =
                 c(prev_tac,
                   round(ratio[ratio$Component %in% c('IndexA', 'IndexB'), 'value'],0),
                   ratio[ratio$Component == 'ratio', 'value'],
                   fpp$meanL, fpp$trl, fpp$fpp,
                   round(c(Inow, Itrigger, Itrigger/1.4), 0), bsg,
                   imult,
                   initial_tac, ifelse(tac == initial_tac, 0, 1),
                   tac,
                   round((tac-prev_tac)/prev_tac*100, 0)),
               type =
                 c('advice',
                   rep('stock_biomass_trend', 3),
                   rep('fishing_pressure_proxy', 3),
                   rep('biomass_safeguard', 4),
                   'precautionary_multiplier',
                   rep('advice', 4)))

  return(tibble::as_tibble(out))
}

#' @title F-proxy rule for category 3 stocks
#' @description Calculates the advised catch based on the category 3 CHR rule.
#'
#' @param data A data-frame containing the columns 'year' and 'index'
#' @param prev_tac The catch advice for the previous advisory year
#' @param fproxy f-proxy
#' @param Itrigger Itrigger which is defined as 1.4*Iloss. Generally, Iloss is defined as the lowest observed index value (this is assumed if Itrigger is NULL)
#' @param stock_k The growth parameter 'K'
#'
#' @return A dataframe with the advice for the current year and information used to reach this value. 'final_advice' is the advice after the biomass safeguard is considered, the 'initial_advice' is the value prior to this step.
#' @export
fproxy_rule <- function(data,
                        prev_tac,
                        fproxy,
                        Itrigger = NULL,
                        stock_k){

  if (!all(c('year', 'index') %in% names(data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }

  ## Get current indice
  data <- data[order(data$year, decreasing = TRUE),]
  Inow <- data$index[1]

  ## If Itrigger not specified, assume is lowest value
  if (is.null(Itrigger)){
    Itrigger <- 1.4*min(data$index, na.rm = TRUE)
    cat('Assuming Iloss is equal to the lowest observed index value of ', Itrigger/1.4)
  }

  ## Biomass safeguard
  bsg <- biomass_safeguard(Inow = Inow, Itrigger = Itrigger)

  ## Multiplier based on stock growth
  imult <- multiplier_lookup(stock_k)

  ## Calculate prelininary advice
  initial_tac <- Inow * fproxy * bsg * imult

  ## Apply stability clause for final tac
  tac <- stability_clause(tac = initial_tac,
                          prev_tac = prev_tac,
                          bsg = bsg)

  out <-
    data.frame(Component =
                 c('previous_catch_advice',
                   'biomass_index',                                              ## Last years index
                   'Fmsy_proxy',                                                 ## Fishing pressure proxy
                   'last_index_value', 'Itrigger', 'Iloss', 'biomass_safeguard', ## Biomass safeguard
                   'multiplier',                                                 ## Precautionary multiplier
                   'initial_catch_advice',
                   'stability_clause_applied',
                   'catch_advice',
                   'advice_change'),
               value =
                 c(prev_tac,
                   Inow,
                   fproxy,
                   round(c(Inow, Itrigger, Itrigger/1.4), 0), bsg,
                   imult,
                   initial_tac, ifelse(tac == initial_tac, 0, 1),
                   tac,
                   round((tac-prev_tac)/prev_tac*100, 0)),
               type =
                 c('advice',
                   'biomass_index',
                   rep('fishing_pressure_proxy', 1),
                   rep('biomass_safeguard', 4),
                   'precautionary_multiplier',
                   rep('advice', 4)))

  return(tibble::as_tibble(out))
}

#' @title RB rule for category 3 stocks
#' @description Calculates the advised catch based on the category 3 RB rule. This rule is run as a last resort if length data is not available and the stock is not short-lived.
#'
#' @param data A data-frame containing the columns 'year' and 'index'
#' @param prev_tac The catch advice for the previous advisory year
#' @param Itrigger Itrigger which is defined as 1.4*Iloss. Generally, Iloss is defined as the lowest observed index value (this is assumed if Itrigger is NULL)
#'
#' @return A dataframe with the advice for the current year and information used to reach this value. 'final_advice' is the advice after the biomass safeguard is considered, the 'initial_advice' is the value prior to this step.
#' @export
#'
#'
base_rule <- function(data,
                      prev_tac,
                      Itrigger = NULL){

  if (!all(c('year', 'index') %in% names(data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }

  ## Get current indice
  data <- data[order(data$year, decreasing = TRUE),]
  Inow <- data$index[1]

  ## If Itrigger not specified, assume is lowest value
  if (is.null(Itrigger)){
    Itrigger <- 1.4*min(data$index, na.rm = TRUE)
    cat('Assuming Iloss is equal to the lowest observed index value of ', Itrigger/1.4)
  }

  ## Two over three
  ratio <- calc_ratio(data, num = 2, den = 3)

  ## Biomass safeguard
  bsg <- biomass_safeguard(Inow = Inow, Itrigger = Itrigger)

  ## ICES advise a multipler of 0.5 for this rule
  imult <- 0.5

  ## Calculate prelininary advice
  initial_tac <- prev_tac * ratio['ratio', 'value'] * bsg * imult

  ## Apply stability clause for final tac
  tac <- stability_clause(tac = initial_tac,
                          prev_tac = prev_tac,
                          bsg = bsg)

  ## Gather output
  out <-
    data.frame(Component =
                 c('previous_catch_advice',
                   'index_A', 'index_B', 'index_ratio',                          ## Stock biomass trend
                   'last_index_value', 'Itrigger', 'Iloss', 'biomass_safeguard', ## Biomass safeguard
                   'multiplier',                                                 ## Precautionary multiplier
                   'initial_catch_advice',
                   'stability_clause_applied',
                   'catch_advice',
                   'advice_change'),
               value =
                 c(prev_tac,
                   round(ratio[ratio$Component %in% c('IndexA', 'IndexB'), 'value'],0),
                   ratio[ratio$Component == 'ratio', 'value'],
                   round(c(Inow, Itrigger, Itrigger/1.4), 0), bsg,
                   imult,
                   initial_tac, ifelse(tac == initial_tac, 0, 1),
                   tac,
                   round((tac-prev_tac)/prev_tac*100, 0)),
               type =
                 c('advice',
                   rep('stock_biomass_trend', 3),
                   rep('biomass_safeguard', 4),
                   'precautionary_multiplier',
                   rep('advice', 4)))

  return(tibble::as_tibble(out))
}



