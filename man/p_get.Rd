% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/trackr.R
\name{p_get}
\alias{p_get}
\title{Get the trackr history graph}
\usage{
p_get(.data)
}
\arguments{
\item{.data}{- a dataframe which may be grouped}
}
\value{
the history graph
}
\description{
Get the trackr history graph
}
\examples{
iris \%>\% p_comment("A comment") \%>\% p_get()
}
