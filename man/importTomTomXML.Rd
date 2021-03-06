% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/import_xml.R
\name{importTomTomXML}
\alias{importTomTomXML}
\title{Import tomtom data from previous run}
\usage{
importTomTomXML(tomtom_xml_path)
}
\arguments{
\item{tomtom_xml_path}{path to tomtom.xml}
}
\value{
will return data.frame with input motifs & results for best match.
  `tomtom` list column contains full tomtom data for each input motif.
  NOTE: if tomtom detects no matches for any input motif, currently will
  print a message & return NA values for `tomtom`, `best_match_name`, and
  `best_match_motif`.
}
\description{
Import tomtom data from previous run
}
\details{
tomtom list column format
the `tomtom` list column contains data.frames with the following format:
    - name: name of query PWM
    - altname: alternate name of query PWM
    - match_name: name of matched PWM
    - match_altname: alt name of matched PWM
    - match_pval: p-value of match
    - match_eval: E-value of match
    - match_qval: q-value of match
    - match_offset: number of letters the query was offset from the target match
    - match_strand: whether the motif was found on input strand (+) or as reverse-complement (-)
    - db_name: database source of matched motif
    - match_motif: universalmotif object containing the PWM that was matched
}
\examples{
tomtom_xml <- system.file("extdata", "tomtom.xml", package = "memes")
importTomTomXML(tomtom_xml)
}
\seealso{
[runTomTom()]
}
