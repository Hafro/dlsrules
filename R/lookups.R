#' @title Multiplier lookup
#' @description Multiplier applied to the harvest control rule to maintain the probability of the biomass declining below Blim to less than 5%. Ranges from 0 to 1.0.
#'
#' @param stock_k The growth parameter 'K' (from von b equation)
#'
#' @return A multiplier that is specific to the stock's K
#' @export
multiplier_lookup <- function(stock_k){

  if (stock_k < 0.2){
    return(0.95)
  }
  else{
    if (stock_k >= 0.2 && stock_k < 0.32){
      return(0.9)
    }
    else{
      print("'K' is greater than 0.32 therefore apply the CHR rule")
      if (stock_k >= 0.32 && stock_k < 0.45){
        return(0.5)
      }
      else{
        stop("k >= 0.45: use Method 3 (short-lived species), not the rfb/chr rule.")
      }  
    }
  }
}

