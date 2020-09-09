
##
## Quick thing to get ward stats into excel
##

rm(list=ls())

library(civis)
library(geneorama)
library(colorspace)

sourceDir("functions")

## Steps to read civis data
## For key setup, see https://civisanalytics.github.io/civis-r/
source("config/setkey.R")

civis_ward_table <- read_civis_query("select * from cic.ward_visualization_table")
d <- copy(civis_ward_table)

setkey(d, ward)
d$hover_text <- NULL
d$rank <- 50 - rank(d$percent_to_target) + 1

colnames(d)
setnames(d, "civis_2020_target", "civis_2020_prediction")
setnames(d, "pct_spanish_speaking", "percent_spanish_speaking")
setcolorder(d,c("ward", "current_response_rate", "civis_2020_prediction", 
                "adjusted_civis_2020_target", "percent_to_target", "rank", 
                "low_response_score", 
                "mail_return_rate_cen_2010", "return_rate_cen_2020", 
                "tot_occp_units_acs_13_17", "counted_households", "uncounted_households", 
                "percent_counted", "percent_uncounted", "percent_spanish_speaking"))


setnames(d, gsub("_", " ", colnames(d)))
for(l in letters){
  setnames(d, 
           gsub(paste0(" ", l),
                paste0(" ", toupper(l)),
                colnames(d)))
  setnames(d, 
           gsub(paste0("^", l),
                paste0(toupper(l)),
                colnames(d)))
}
setnames(d, gsub("Acs", "ACS", colnames(d)))
setnames(d, gsub("Cen ", "Census ", colnames(d)))
pcts <- c('Current Response Rate', 'Civis 2020 Prediction', 'Adjusted Civis 2020 Target',
          'Mail Return Rate Census 2010', 'Return Rate Census 2020',
          'Low Response Score', 'Percent Counted', 'Percent Uncounted', 'Percent To Target',
          'Percent Spanish Speaking')
cmmas <- c('Tot Occp Units ACS 13 17', 'Counted Households', 'Uncounted Households')
d[ , eval(pcts) := lapply(.SD, function(x) x / 100), .SDcols = pcts]
d[ , eval(cmmas) := lapply(.SD, prettyNum, big.mark = ","), .SDcols = cmmas]

# clipper(d)

pal <- colorRampPalette(c("red", "darkorange", "gold", "limegreen","forestgreen"))
cols <- pal(100)
plot(1:100,col=cols, pch = 16)

v <- d$`Percent To Target`
# # v <- 
# v <- sort(v)
#   (max(v) -v)/diff(range(v))
# intervals::
# v

library(leaflet)
pal <- colorNumeric(palette = cols, domain = v)
pal(v)
plot(1:50,col=pal(v), pch=16)
d$col <- pal(v)

# clipper(d)


