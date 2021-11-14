#' Matching your data with cshapes if you have country war codes.
#'
#' \code{name_code} function to get country name in cshapes if you have war code.
#' It also provides you start and end date.
#'
#' @param warcode Country war code (https://correlatesofwar.org/data-sets/cow-country-codes).
#' @return The output will be the country name as it appears in cshapes, start and end date of the country in cshapes data.
#' @example
#' name_code(2)
#' @export
name_code <- function(warcode) {
  cs2<-cshp(date = NA, useGW = TRUE, dependencies = FALSE)
  namecountry<- unique(cs2$country_name[cs2$gwcode==warcode])
  startcountry<- unique(cs2$start[cs2$gwcode==warcode])
  endcountry<- unique(cs2$end[cs2$gwcode==warcode])
  return(list(namecountry, "Start date", startcountry, "End date", endcountry))
}
#' Matching your data with cshapes - list of country names.
#'
#' \code{names_list} this function provides you with the list of all country names in cshapes.
#'
#' @return The output will be a list of all country name in cshapes.
#' @example
#' name_list()
#' @export
names_list <- function(a) {
  cs2<-cshp(date = NA, useGW = TRUE, dependencies = FALSE)
  x <- unique(cs2$country_name)
  return(x)
}
#' Matching your data with cshapes if you have country names.
#'
#' \code{name_text} function to get country war codes, start and ending dates if you have country name.
#'
#' @param countryname Country name as it appears in cshapes.
#' @return The output will be the country war code, start and end date of the country in cshapes data.
#' @example
#' name_text("Uruguay")
#' @export
name_text <- function(countryname) {
  cs2<-cshp(date = NA, useGW = TRUE, dependencies = FALSE)
  gwcodecountry<- unique(cs2$gwcode[cs2$country_name==countryname])
  startcountry<- unique(cs2$start[cs2$country_name==countryname])
  endcountry<- unique(cs2$end[cs2$country_name==countryname])
  return(list("War code", gwcodecountry, "Start date", startcountry, "End date", endcountry))
}
