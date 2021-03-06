% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/matching_names.R
\name{name_code}
\alias{name_code}
\title{Matching your data with cshapes if you have country Correlates of War (COW) codes (cowcode).}
\usage{
name_code(cowcode)
}
\arguments{
\item{cowcode}{Country Correlates of War code (cowcode).}
}
\value{
The output will be the country name as it appears in cshapes, as well as the country's entry into and exit from cshapes dates.
}
\description{
\code{name_code} A function to get the country name in cshapes, if you have the cowcode.
It also provides the country's entry into and exit from cshapes dates.
}
\examples{
name_code(2)
}
