#This script assumes you have run global.R prior to running this script. 

#Initialize libraries
library(knitr)
library(markdown)
library(rmarkdown)
library(sf)
library(tmap)
library("leaflet")
library("colorspace")
library("rgdal")

#merge data frames into shapefile 
# 
shp_tracts@data <- base::merge(y = civisdata, x = shp_tracts@data, by.y = "gidtr", by.x = "GEOID")
shp_tracts@data <- base::merge(y = htc, x = shp_tracts@data, by.y = "GEOIDtxt", by.x = "GEOID") 

tmap_mode("view")

for(ward in sort(unique(shp_wards@data$ward))){
    rmarkdown::render("app/CensusWardReport.Rmd", 
                      output_file =  paste("report_", ward, '_', Sys.Date(), ".html", sep=''), 
                      output_dir = "WardReports")
}
