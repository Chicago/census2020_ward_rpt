#This script assumes you have run global.R prior to running this script. 

rm(list=ls())
source("app/global.R")

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

#merge data frames into shapefile 
shp_tracts@data <- base::merge(y = civisdata, x = shp_tracts@data, by.y = "gidtr", by.x = "GEOID")
shp_tracts@data <- base::merge(y = htc, x = shp_tracts@data, by.y = "GEOIDtxt", by.x = "GEOID") 

#This section will come up with ward rankings in terms of response rates
#Start by sectioning out the data
rank <- civis_pdb[, c(1:10, 271:286)]
rank <- as.data.table(rank)

#Create the weighted response value
rank[ , handicap := low_response_score / mean(low_response_score, na.rm=T)]
rank[ , weightedresponse := mail_return_rate_cen_2010 * handicap]

#use the Civis crosswalk file to assign each tract to a ward
#NOTE: There seems to be a problem with this - we lose some rows. Is there a better way to do this?
# crosswalk$census_tract <- crosswalk$census_tract*100
# crosswalk <- as.data.table(crosswalk)
rank <- merge.data.table(x = rank, y = crosswalk, by.x = "tract", by.y = "census_tract") #this line of code is where we lose rows

rankdt<- rank[i = TRUE,
              .(mean_response = mean(mail_return_rate_cen_2010, na.rm = TRUE), 
                mean_handicap = mean(handicap, na.rm = TRUE), 
                mean_weightedresponse = mean(weightedresponse, na.rm = TRUE)), 
              by = "ward"]

rankings <- rank(rankdt$mean_weightedresponse)

#This loop will create ward reports for each of the 50 wards based off of the CensusWardReport.Rmd file
tmap_mode("view")

for(ward in sort(unique(shp_wards@data$ward))){
    rmarkdown::render("app/CensusWardReport.Rmd", 
                      output_file =  paste("report_", ward, '_', Sys.Date(), ".html", sep=''), 
                      output_dir = "reports_by_ward")
}
