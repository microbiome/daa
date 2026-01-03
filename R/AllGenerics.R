# This file contains all the generics

#' @rdname getWilcoxon
#' @export
setGeneric("getWilcoxon", signature = "x", function(x, ...) {
    standardGeneric("getWilcoxon")
})

#' @rdname getWilcoxon
#' @export
setGeneric("addWilcoxon", signature = "x", function(x, ...) {
    standardGeneric("addWilcoxon")
})

#' @rdname getTtest
#' @export
setGeneric("getTtest", signature = "x", function(x, ...) {
    standardGeneric("getTtest")
})

#' @rdname getTtest
#' @export
setGeneric("addTtest", signature = "x", function(x, ...) {
    standardGeneric("addTtest")
})
