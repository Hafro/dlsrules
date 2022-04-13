#' @title Find modal value
#' @description Calculates the mode of a vector of individual measurements
#' 
#' @param x A numeric vector of individual measurements
#' 
#' @return The mode of 'x'
#' @export
calc_mode <- function(x){
  
  uxs <- unique(x)
  xtab <- tabulate(match(x, uxs))
  out <- uxs[xtab == max(xtab)]
  
  if (length(out) > 1){
    warning("multiple modes found")
  }
  return(out)
}