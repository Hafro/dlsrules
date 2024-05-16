#' @title Calculate 'f' component
#' @description Calculates component 'f' for the rfb equation for category 3 stocks.
#' This is the ratio of the mean length (𝐿y−1 ) in the observed catch that is above the length of first capture relative to the target reference
#' length (mean length/target reference length). The target reference length is 𝐿fm = 0.75 Lc + 0.25 Linf, where Lc is defined as length at 50% of modal abundance
#'
#' @param len_data A data frame containing length frequencies. Requires the columns "year", "length", and "n"
#' @param Linf L-infinity from the Von Bertalanffy equation
#' @param assessment_year The current assessment year
#'
#' @return A list containing the length at first capture, Linf, mean length above Lc in previous year, target reference length, and the fishing pressure proxy
#' @export
fishing_pressure_proxy <- function(len_data, Linf, assessment_year){

  ## Aggregate over years
  Ldist <- aggregate(list(n = len_data$n), by = list(length = len_data$length), FUN = sum)

  ## Find the modal abundance and subsequently the length at first capture
  modal_abun <- Ldist$n[which.max(Ldist$n)]
  Lc <- min(Ldist$length[Ldist$n > modal_abun*0.5])

  ## Mean length above Lc in previous year
  meanL <- len_data[len_data$year == (assessment_year - 1) & len_data$length > Lc,]
  meanL <- sum(meanL$length*meanL$n)/sum(meanL$n)

  ## Target reference length
  trl <- target_reference_length(Lc, Linf)

  ## Fishing pessure proxy
  fpp <- meanL / trl

  return(list(Linf = Linf, Lc = Lc, meanL = meanL, trl = trl, fpp = fpp))
}

#' @title Calculate 'f' component
#' @description Calculates component 'f' for the rfb equation for category 3 stocks.
#' This is the ratio of the mean length (𝐿y−1 ) in the observed catch that is above the length of first capture relative to the target reference
#' length (mean length/target reference length). The target reference length is 𝐿fm = 0.75 Lc + 0.25 Linf, where Lc is defined as length at 50% of modal abundance
#'
#' @param meanL The mean length in the observed catch that is above the length of first capture
#' @param Lc The length at first capture (defined as the length at 50% of modal abundance)
#' @param Linf L-infinity from the Von Bertalanffy equation
#'
#' @return The ratio between meanL and the target reference length
#' @export
calc_f <- function(meanL, Lc, Linf){
  return(meanL / target_reference_length(Lc, Linf))
}

#' @describeIn calc_f
#'
#' @return Target reference length
#' @export
target_reference_length <- function(Lc, Linf){
  return(0.75*Lc + 0.25*Linf)
}

#' @title Calculate index ratio
#' @description Calculates the ratio between the means of two adjacent periods for an index (or anything called 'index')
#'
#' @param data A dataframe containing the columns 'year' and 'index'
#' @param num The number of years (backwards from the final year) to calculate the mean for 'indexA' e.g. for 2/3, num = 2
#' @param den The number of years (backwards from the 'num' years) to calculate the mean for 'indexB'  e.g. for 2/3, num = 3
#'
#' @return The ratio between indexA and indexB
#' @export
calc_ratio <- function(data, num = 2, den = 3){

  if (!all(c('year', 'index') %in% names(data))){
    stop("The input dataframe must have the columns 'year' and 'index'")
  }

  data <- data[order(data$year, decreasing = TRUE),]
  indexA <- mean(data$index[1:num])
  indexB <- mean(data$index[(num+1):(num+den)])

  out <- data.frame(Component = c('IndexA', 'IndexB', 'ratio'),
                    value = c(indexA, indexB, indexA/indexB))
  row.names(out) <- out$Component

  return(out)

}

#' @title Stability clause
#' @description Limits the amount the advised catch can change upwards or downwards between years. The previous year's advised catch +20% and -30% act as bounds for the new advised catch.
#'
#' @param tac The advised catch for the current assessment period (the advised catch resulting from the rfb rule)
#' @param prev_tac Previous year's advised catch
#' @param bsg Biomass safeguard (obtained from the function 'biomass_safeguard')
#'
#' @return The advised catch after the stability clause has been applied
#' @export
stability_clause <- function(tac, prev_tac, bsg){

  ## The biomass safeguard does not apply if the biomass safeguard is < 1
  if (bsg < 1){
    return(tac)
  }
  else{
    return(min(max(0.7*prev_tac, tac), 1.2*prev_tac))
  }

}

#' @title Uncertainty cap
#' @description Limits the amount the advised catch can change upwards or downwards between years. The previous year's advised catch +20% and -20% act as bounds for the new advised catch.
#'
#' @param tac The advised catch for the current assessment period
#' @param prev_tac Previous year's advised catch
#' @param cap Percentage change for the cap, assumed to be symmetrical
#'
#' @return The advised catch after the uncertainty cap has been applied
#' @export
uncertainty_cap <- function(tac, prev_tac, cap = 20){
  upper_cap <- 1 + cap/100
  lower_cap <- 1 - cap/100
  return(min(max(lower_cap*prev_tac, tac), upper_cap*prev_tac))
}

#' @title Precautionary buffer
#' @description Applies a precautionary margin to the advice
#'
#' @param tac The advised catch for the current assessment period
#' @param buffer Percentage decrease for the buffer
#'
#' @return The advised catch after the precautionary buffer has been applied
#' @export
precautionary_buffer <- function(tac, buffer = 20){
  return((1 - buffer/100)*tac)
}

#' @title Biomass safeguard
#' @description Adjustment to reduce catch when the most recent index data is less than Itrigger. Here, Itrigger is the breakpoint below which the stock state deteriorates.
#'
#' @param Inow The most recent index value
#' @param Itrigger Itrigger which is defined as 1.4*Iloss. Generally, Iloss is defined as the lowest observed index value.
#'
#' @return Numeric scalar
#' @export
biomass_safeguard <- function(Inow, Itrigger){
  return(min(1, Inow/Itrigger))
}

