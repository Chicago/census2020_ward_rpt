#This script will generate reports for each Chicago Community Area
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
library(reactable)

#merge data frames into shapefile 
# 
shp_tracts@data <- base::merge(y = civisdata, x = shp_tracts@data, by.y = "gidtr", by.x = "GEOID")
shp_tracts@data <- base::merge(y = htc, x = shp_tracts@data, by.y = "GEOIDtxt", by.x = "GEOID") 

tmap_mode("view")

for(community in sort(unique(shp_community@data$community))){
    rmarkdown::render("app/CensusCAReport.Rmd", 
                      output_file =  paste("report_", community, '_', Sys.Date(), ".html", sep=''), 
                      output_dir = "CAReports")
}
