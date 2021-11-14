#' Estimates a Spatial AutoRegressive (SAR) lag model.
#'
#' \code{ntspreg} estimates a Spatial AutoRegressive (SAR) model (spatialreg::lagsarlm)
#' using the nearest neighbor spatial weights matrix you previously created
#' and a linear regression model.
#'
#' @param lmobj An object created by the \code{lm} function.
#' @param wm neighbor spatial weight matrix created by the \code{make_ntspmat}.
#' @return The output will be SAR model estimated.
#' @example
#' sar_reex <- ntspreg(ols,wm)
#' @import spdep
#' @export
ntspreg <- function(lmobj,wm) {

  weights <- mat2listw(wm, row.names=NULL, style="W")
  nblist <-weights$neighbours
  listw <-nb2listw(nblist)

  formula <- lmobj[["call"]][["formula"]]
  esample<-rownames(as.matrix(lmobj[["residuals"]]))
  df <- eval(lmobj[["call"]][["data"]])
  df <- df[esample,]

  lag = spatialreg::lagsarlm(formula, data=df, listw=listw ,method="eigen",zero.policy=TRUE, tol.solve=1.0e-10)
  return(lag)
}
#' Estimates a Spatial error model (SEM) lag model.
#'
#' \code{ntsperr} estimates a Spatial error model (SEM) model (spatialreg::errorsarlm)
#' using the nearest neighbor spatial weights matrix you previously created
#' and a linear regression model.
#'
#' @param lmobj An object created by the \code{lm} function.
#' @param wm neighbor spatial weight matrix created by the \code{make_ntspmat}.
#' @return The output will be SAR model estimated.
#' @example
#' sdem_reex <- ntsperr(ols,wm)
#' @export
ntsperr <- function(lmobj,wm) {

  weights <- mat2listw(wm, row.names=NULL, style="W")
  nblist <-weights$neighbours
  listw <-nb2listw(nblist)

  formula <- lmobj[["call"]][["formula"]]
  esample<-rownames(as.matrix(lmobj[["residuals"]]))
  df <- eval(lmobj[["call"]][["data"]])
  df <- df[esample,]

  err = spatialreg::errorsarlm(formula, data=df, listw=listw ,method="eigen",zero.policy=TRUE, tol.solve=1.0e-11)
  return(err)
}
#' Estimates a Spatial Autocorrelation (SAC) lag model.
#'
#' \code{ntspsac} estimates a Spatial Autocorrelation (SAC) model (spatialreg::sacsarlm)
#' using the nearest neighbor spatial weights matrix you previously created
#' and a linear regression model.
#'
#' @param lmobj An object created by the \code{lm} function.
#' @param wm neighbor spatial weight matrix created by the \code{make_ntspmat}.
#' @return The output will be SAR model estimated.
#' @example
#' sac_reex <- ntsperr(ols,wm)
#' @export
ntspsac <- function(lmobj,wm) {

  weights <- mat2listw(wm, row.names=NULL, style="W")
  nblist <-weights$neighbours
  listw <-nb2listw(nblist)

  formula <- lmobj[["call"]][["formula"]]
  esample<-rownames(as.matrix(lmobj[["residuals"]]))
  df <- eval(lmobj[["call"]][["data"]])
  df <- df[esample,]

  sac = spatialreg::sacsarlm(formula, data=df, listw=listw ,method="eigen",zero.policy=TRUE, tol.solve=1.0e-10)
  return(sac)
}
