# Potential functions ----------------------------------------------------------
# 2022-05-31
#  May or may not change, including name of the function
#  Hence functions not currently exported

#' The length or age of first capture
#' 
#' The function returns the length or age class where catch is at or above a certain
#' portion of the frequency mode.
#' 
#'
#' @param x length or age
#' @param y bin count of length or age, normally observed catches
#' @param p the proportion of the modal. 0.5 (the default) is from the ICES bible.
#'
#' @return A vector of lengths or age of first captures
#'
dl_1st_capture <- function(x, y, p = 0.5) {
  i <- x >= p * max(y)
  return(min(x[i]))
}
#' Mean length or age in the catch above length or age of first capture
#'
#' @param x length or age
#' @param y bin count of length or age, normally observed catches
#' @param first length or age of first capture
#'
#' @return A vector of the mean length or age of the catch
#'
dl_mean <- function(x, y, first) {
  sum(x[x > first] * y[x > first]) / sum(y[x > first])
}