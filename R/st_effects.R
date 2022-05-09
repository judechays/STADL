#' Total, Direct, and Indirect Spatiotemporal Effects for the STADL (sy0,ty1) Model.
#'
#' \code{st_effects} calculates both the short and long-run total, direct and indirect effects of shocks to sample units' covariates using the last cross-section of the data.
#'
#' @param spobj An object created by the \code{ntspreg} function for a STADL (sy0,ty1) Model.
#' @param wm a list created by the \code{make_ntspmat} function that includes the spatial weights    #' matrix.
#' @param tlag Name of a variable that identifies the temporal lag of an outcome.
#' @param covariate Name of a variable to be shocked.
#' @return The output will be a dataframe.
#'
#'
#' @import dplyr
#' @importFrom stats na.omit
#' @importFrom sf as_Spatial
#' @importFrom Matrix bdiag
#' @importFrom lubridate year
#' @import cshapes
#' @import stargazer
#' @export


#' @examples
#'  \dontrun{
#' fx <- st_effects(sar,wm,tlag,x)
#' }

st_effects <- function(spobj,wm,tlag,covariate) {

  call <- match.call()
  df <- wm[[1]]
  yi<- df[,wm[[4]]]
  yit <- as.character(wm[[4]])
  dim0 <- as.numeric(length(which(eval(parse(text = noquote(paste("df$",yit,sep="")))) < max(yi))))
  dim1 <- as.numeric(length(which(df$year == max(yi))))

  W <- as.matrix(wm[[2]]/rowSums(wm[[2]]))
  W <- W[(dim0+1):(dim0+dim1),(dim0+1):(dim0+dim1)]

  b <- spobj[["coefficients"]][[as.character(call$covariate)]]
  r <- summary(spobj)$rho
  p <- spobj[["coefficients"]][[as.character(call$tlag)]]


  direct_sr <- round(mean(diag(solve(diag(dim1) - r*W)*b)), digits=3)
  indirect_sr <- round(mean(colSums((solve(diag(dim1) - r*W)*b)) - diag(solve(diag(dim1) - r*W)*b)), digits=3)
  total_sr <- direct_sr + indirect_sr

  direct_lr <- round(mean(diag(solve(diag(dim1) - r*W)*(b/(1-p)))), digits=3)
  indirect_lr <- round(mean(colSums((solve(diag(dim1) - r*W)*(b/(1-p)))) - diag(solve(diag(dim1) - r*W)*(b/(1-p)))), digits=3)
  total_lr <- direct_lr + indirect_lr

matcell <- c("Direct Short-Run:", "Indirect Short-Run:", "Total Short-Run:", "Direct Long-Run:", "Indirect Long-Run:", "Total Long-Run:", direct_sr,  indirect_sr, total_sr, direct_lr, indirect_lr,total_lr)
fx <- as.data.frame(matrix(matcell,nrow=6,ncol=2))
colnames(fx)<-c("Effect", "Size")
  return(fx)

}
