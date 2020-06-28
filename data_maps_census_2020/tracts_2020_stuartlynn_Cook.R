
##
## This is based off my "Estimates for 2020.R" file
##


##==============================================================================
## INITIALIZE
##==============================================================================

rm(list=ls())

library(geneorama) ## Not actually needed
library(data.table)
library("rgeos")
library("leaflet")
library("colorspace")
library("sp")
# library("spdep")
library("rgdal")
library("RColorBrewer")
# library("ggplot2")
# library("bit64")

sourceDir("functions/")


##==============================================================================
## IMPORT IL DATA
##==============================================================================

shp_community <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shp_il <- readOGR("data_maps_census_2020/tracts_2020_stuartlynn_IL.geojson", 
                  stringsAsFactors = FALSE)


##==============================================================================
## Create city outline from community areas
##==============================================================================
shp_city_outline <- gUnaryUnion(as(shp_community, "SpatialPolygons"))

##==============================================================================
## Limit to Cook
##==============================================================================
shp_cook <- shp_il[shp_il@data$COUNTY == "031", ]
summary(shp_cook)


## sanity check 1
# plot(shp_cook)

## sanity check 2
# leaflet() %>%
#     addProviderTiles("Stamen.TonerHybrid") %>%
#     addPolygons(data = shp_cook, fill = T, color = "black",
#                 fillColor = "grey", weight = 1, fillOpacity = 1)

## sanity check 3
## this one makes it clear that O'Hare and Midway are missing
# leaflet() %>%
#     addProviderTiles("Stamen.TonerHybrid") %>%
#     addPolygons(data = shp_city_outline, fill = T, color = "black",
#                 fillColor = "yellow", weight = 1, fillOpacity = 1) %>%
#     addPolygons(data = shp_cook, fill = T, color = "black",
#                 fillColor = "black", weight = 1, fillOpacity = 1)


# file.remove("data_maps_census_2020/tracts_2020_stuartlynn_Cook.geojson")
writeOGR(obj = shp_cook, 
         dsn = "data_maps_census_2020/tracts_2020_stuartlynn_Cook.geojson", 
         layer = "tracts", 
         driver = "GeoJSON")



##==============================================================================
## Limit to chicago 
##==============================================================================

## Calculate intersection
shp_cook_wgs84 <- spTransform(shp_cook, CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_cityoutline_wgs84 <- spTransform(shp_city_outline,  CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_chicago_wgs84 <- gIntersection(spgeom1 = shp_cook_wgs84,
                                   spgeom2 = shp_cityoutline_wgs84,
                                   byid = TRUE,
                                   id = NULL,
                                   drop_lower_td = TRUE,
                                   unaryUnion_if_byid_false = TRUE,
                                   checkValidity = FALSE)
plot(shp_chicago_wgs84, col='yellow')
plot(shp_cook_wgs84, add=T, col='blue')
plot(shp_cityoutline_wgs84, add=T, col='red')
plot(shp_chicago_wgs84, add=T, col='yellow')

ids_chicago <- sapply(shp_chicago_wgs84@polygons, function(x)x@ID)
ids_cook <- sapply(shp_cook_wgs84@polygons, function(x)x@ID)
ids_cook <- paste(ids_cook, "1")
inin(ids_chicago, ids_cook)
ii <- match(ids_chicago, ids_cook)
shp_chicago_wgs84_withdata <- SpatialPolygonsDataFrame(shp_chicago_wgs84, 
                                                       data = shp_cook@data[ii,],
                                                       match.ID = FALSE)
str(shp_chicago_wgs84_withdata@data)

writeOGR(obj = shp_chicago_wgs84_withdata, 
         dsn = "data_maps_census_2020/tracts_2020_stuartlynn_Chicago.geojson", 
         layer = "tracts", 
         driver = "GeoJSON")

