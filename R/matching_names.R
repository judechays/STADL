#' Matching your data with cshapes if you have country Correlates of War (COW) codes (cowcode).
#'
#' \code{name_code} A function to get the country name in cshapes, if you have the cowcode.
#' It also provides the country's entry into and exit from cshapes dates.
#'
#' @param cowcode Country Correlates of War code (cowcode).
#' @return The output will be the country name as it appears in cshapes, as well as the country's entry into and exit from cshapes dates.
#' @examples
#' name_code(2)
#' @importFrom cshapes cshp
#' @export
name_code <- function(cowcode) {
  cs2<-cshp(date = NA, useGW = FALSE, dependencies = FALSE)
  namecountry<- unique(cs2$country_name[cs2$cowcode==cowcode])
  startcountry<- unique(cs2$start[cs2$cowcode==cowcode])
  endcountry<- unique(cs2$end[cs2$cowcode==cowcode])
  return(list(namecountry, "Start date", startcountry, "End date", endcountry))
}
#' Matching your data with cshapes - list of country names.
#'
#' \code{names_list} this function provides you with the list of all country names in cshapes.
#'
#' @param a it can be anything, or left empty.
#' @return The output will be a list of all country name in cshapes.
#' @examples

#' names_list()

#' @export
names_list <- function(a) {
  cs2<-cshp(date = NA, useGW = FALSE, dependencies = FALSE)
  x <- unique(cs2$country_name)
  return(x)
}
#' Matching your data with cshapes if you have country names.
#'
#' \code{name_text} function to get country COW codes, start and ending dates if you have a country's name.
#'
#' @param countryname Country name as it appears in cshapes.
#' @return The output will be the country COW code, start and end date of the country in cshapes data.
#' @examples
#' name_text("Uruguay")
#' @export
name_text <- function(countryname) {
  cs2<-cshp(date = NA, useGW = FALSE, dependencies = FALSE)
  cowcodecountry<- unique(cs2$cowcode[cs2$country_name==countryname])
  startcountry<- unique(cs2$start[cs2$country_name==countryname])
  endcountry<- unique(cs2$end[cs2$country_name==countryname])
  return(list("Correlates of War Code", cowcodecountry, "Start date", startcountry, "End date", endcountry))
}
