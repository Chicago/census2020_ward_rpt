#This script assumes you have run global.R prior to running this script. 
app
rm(list=ls())
source("global.R")

#Initialize libraries
library(knitr)
library(markdown)
library(rmarkdown)
library(sf)
library(tmap)
library(leaflet)
library(colorspace)
library(rgdal)
library(reactable)
library(sp)

#merge data frames into shapefile 
shp_tracts@data <- base::merge(y = civis_pdb, x = shp_tracts@data, by.y = "gidtr", by.x = "GEOID")
shp_tracts@data <- base::merge(y = htc, x = shp_tracts@data, by.y = "GEOIDtxt", by.x = "GEOID")


#This section will come up with ward rankings in terms of response rates
#Start by sectioning out the data
# rank <- civis_pdb[ , c(1:10, 271:286)]
# rank <- as.data.table(rank)


rankdt<- civis_pdb[i = TRUE,
                   j= list(mean_response = mean(mail_return_rate_cen_2010, na.rm = TRUE), 
                           mean_handicap = mean(handicap, na.rm = TRUE), 
                           mean_weightedresponse = mean(weightedresponse, na.rm = TRUE)), 
                   by = "ward"]
rankings <- rank(rankdt$mean_weightedresponse)

#This loop will create ward reports for each of the 50 wards based off of the CensusWardReport.Rmd file
tmap_mode("view")

for(ward in sort(unique(shp_wards@data$ward))){
    rmarkdown::render("CensusWardReport.Rmd", 
                      output_file =  paste("report_", ward, '_', Sys.Date(), ".html", sep=''), 
                      output_dir = "reports_by_ward")
}
