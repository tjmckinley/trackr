% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/trackr.R
\name{p_clear}
\alias{p_clear}
\title{Clear the trackr history graph}
\usage{
p_clear(.data)
}
\arguments{
\item{.data}{- a dataframe which may be grouped}
}
\value{
the hisotry graph
}
\description{
Clear the trackr history graph
}
\examples{
mtcars \%>\% p_comment("A comment") \%>\% p_clear() \%>\% p_get()
}
