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
#' @param ref_points A list with the following elements: 'K', 'Linf', 'Lc', 'I_lim', 'target_reference_length', 'I_trigger'
#' @param index_data The survey index, must contain 'year' and 'index' columns
#' @param len_data A data frame containing length frequencies. Requires the columns "year", "length", and "n"
#' @param prev_tac The preceding assessment year's tac
#' @param assessment_year The current assessment year
#'
#' @return A dataframe with the advice for the current year and information used to reach this value. 'final_advice' is the advice after the biomass safeguard is considered, the 'initial_advice' is the value prior to this step.
#' @export
rfb_rule <- function(ref_points,
                     index_data,
                     len_data,
                     prev_tac,
                     assessment_year){
  
  if (!('K' %in% names(ref_points))){
    stop("The ref_points list must contain a 'K' element")
  }
  if (!('target_reference_length' %in% names(ref_points))){
    if (all(c('Linf', 'Lc') %in% names(ref_points))){
      ref_points$target_reference_length <-
        target_reference_length(Lc = ref_points$Lc, Linf = ref_points$Linf)
    }else{
      stop("The ref_points list must contain either a 'target_reference_length' element or both 'Linf' and 'Lc' elements")
    }
  }
  if (!('I_trigger' %in% names(ref_points))){
    if ('I_lim' %in% names(ref_points)){
      ref_points$I_trigger <- calc_Itrigger(ref_points$I_lim)
    }else{
      ## If Itrigger not specified, assume is lowest value
      Itrigger <- 1.4*min(data$index, na.rm = TRUE)
      cat('Assuming Iloss is equal to the lowest observed index value of ', Itrigger/1.4)
    }
  }
  
  if (!all(c('year', 'index') %in% names(index_data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }
  if (!all(c('year', 'length', 'n') %in% names(len_data))){
    stop("The length frequency dataframe must have the columns 'year', 'length', and 'n'")
  }
  
  ## Get current indice
  index_data <- index_data[order(index_data$year, decreasing = TRUE),]
  Inow <- index_data$index[1]
  
  ## Two over three
  ratio <- calc_ratio(index_data, num = 2, den = 3)
  
  ## Fishing pressure proxy
  fpp <- fishing_pressure_proxy(len_data,
                                Linf = ref_points$Linf,
                                Lc = ref_points$Lc,
                                assessment_year)
  
  ## Biomass safeguard
  bsg <- biomass_safeguard(Inow = Inow, Itrigger = ref_points$I_trigger)
  
  ## Multiplier based on stock growth
  imult <- multiplier_lookup(ref_points$K)
  
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
                   'mean_catch_length', 'msy_proxy_length',                      ## Fishing pressure proxy
                   'fpp_ratio', 'fpp_ratio_inv',                                 ## Fishing pressure proxy
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
                   fpp$meanL, fpp$trl, 
                   fpp$fpp, fpp$trl/fpp$meanL,
                   round(c(Inow, ref_points$I_trigger, ref_points$I_trigger/1.4), 0), bsg,
                   imult,
                   initial_tac, ifelse(tac == initial_tac, 0, 1),
                   tac,
                   round((tac-prev_tac)/prev_tac*100, 0)),
               type =
                 c('advice',
                   rep('stock_biomass_trend', 3),
                   rep('fishing_pressure_proxy', 4),
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



