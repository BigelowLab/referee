#' Like isTRUE and isFALSE but for vectors
#' 
#' @export
#' @param x logical vector with and without NAs
#' @param na.rm logical, if TRUE remove NAs before consideration, ignore for
#'   \code{any_na()}
#' @return logical vector
is_false = function(x = c(TRUE, FALSE, NA), na.rm = FALSE){
  sapply(x, isFALSE)
}

#' @export
#' @rdname is_false
any_false = function(x = c(TRUE, FALSE, NA)){
  any(is_false(x))
}

#' @export
#' @rdname is_false
is_true = function(x = c(TRUE, FALSE, NA)){
  sapply(x, isTRUE)
}

#' @export
#' @rdname is_false
any_true = function(x = c(TRUE, FALSE, NA)){
  any(is_true(x))
}

#' @export
#' @rdname is_false
any_na = function(x = c(TRUE, FALSE, NA)){
  any(is.na(x))
}

#' @export
#' @rdname is_false
all_true = function(x = c(TRUE, FALSE, NA)){
  all(is_true(x))
}

#' @export
#' @rdname is_false
all_false = function(x = c(TRUE, FALSE, NA)){
  all(is_false(x))
}


#' Quick and dirty wrapper around table
#' 
#' @export
#' @param x object to tabulate
#' @param useNA char, by default "always"
#' @param ... other arguments passed to \code{table}
#' @return tabulation (named vector)
tab = function(x, useNA = "always", ...){
  table(x, useNA = useNA, ...)
}