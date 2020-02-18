#Initialize libraries
library(knitr)
library(markdown)
library(rmarkdown)
library(sf)
library(sp)
library(tmap)
library(dplyr)
library(data.table)
library("rgeos")
library("leaflet")
library("colorspace")
library("rgdal")

#Import data
shp_ward <- readOGR("data_maps/wards.geojson", stringsAsFactors = F)
shp_tracts <- readOGR("data_maps/tracts_trimmed.geojson", stringsAsFactors = F)

for (ward in sort(unique(shp_ward@data$ward))){
    rmarkdown::render("CensusWardReport.Rmd", 
                      output_file =  paste("report_", ward, '_', Sys.Date(), ".html", sep=''), 
                      output_dir = "WardReports")
}
