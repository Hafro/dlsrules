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
#' @param len_ratio Component 'f' of the rfb rule
#'
#' @return A dataframe with the advice for the current year and information used to reach this value. 'final_advice' is the advice after the biomass safeguard is considered, the 'initial_advice' is the value prior to this step.
#' @export
rfb_rule <- function(data,
                     prev_tac,
                     Itrigger = NULL,
                     stock_k,
                     len_ratio){

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

  ## Multiplier based on stock growth
  imult <- multiplier_lookup(stock_k)

  ## Calculate prelininary advice
  initial_tac <- prev_tac * ratio['ratio', 'value'] * len_ratio * bsg * imult

  ## Apply stability clause for final tac
  tac <- stability_clause(tac = initial_tac,
                          prev_tac = prev_tac,
                          bsg = bsg)

  ## Gather output
  out <- rbind(data.frame(Component = 'previous_advice',
                          value = prev_tac),
               ratio,
               data.frame(Component = c('length_ratio',
                                        'biomass_safeguard',
                                        'multiplier',
                                        'initial_advice',
                                        'stability_clause_applied',
                                        'final_advice',
                                        'advice_change'),
                          value = c(len_ratio,
                                    bsg,
                                    imult,
                                    initial_tac,
                                    ifelse(tac == initial_tac, 0, 1),
                                    tac,
                                    round((tac-prev_tac)/prev_tac*100, 0))))

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

  ## Gather output
  out <- rbind(data.frame(Component = 'previous_advice',
                          value = prev_tac),
               data.frame(Component = c('Index',
                                        'fproxy',
                                        'biomass_safeguard',
                                        'multiplier',
                                        'initial_advice',
                                        'stability_clause_applied',
                                        'final_advice',
                                        'advice_change'),
                          value = c(Inow,
                                    fproxy,
                                    bsg,
                                    imult,
                                    initial_tac,
                                    ifelse(tac == initial_tac, 0, 1),
                                    tac,
                                    round((tac-prev_tac)/prev_tac*100, 0))))

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
  out <- rbind(data.frame(Component = 'previous_advice',
                          value = prev_tac),
               ratio,
               data.frame(Component = c('biomass_safeguard',
                                        'multiplier',
                                        'initial_advice',
                                        'stability_clause_applied',
                                        'final_advice',
                                        'advice_change'),
                          value = c(bsg,
                                    imult,
                                    initial_tac,
                                    ifelse(tac == initial_tac, 0, 1),
                                    tac,
                                    round((tac-prev_tac)/prev_tac*100, 0))))

  return(tibble::as_tibble(out))
}



