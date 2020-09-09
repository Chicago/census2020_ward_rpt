
##
## Downloaded file from 
## https://www2.census.gov/geo/tiger/TIGER2019/TRACT/
## And unzipped it to directory that was automatically named "tl_2019_17_tract"

##==============================================================================
## INITIALIZE
##==============================================================================

rm(list=ls())

# library(geneorama) ## Not actually needed
library(data.table)
library("rgeos")
library("leaflet")
library("colorspace")
library("sp")
# library("spdep")
library("rgdal")
# library("RColorBrewer")
# library("ggplot2")
# library("bit64")


# sourceDir("functions/")

##==============================================================================
## DOWNLOAD DATA
##==============================================================================

shp_ward <- readOGR("data_maps/wards.geojson", stringsAsFactors = F)
str(shp_ward, 2)


shp_il <- rgdal::readOGR("data_maps/tl_2019_17_tract", stringsAsFactors = F)
str(shp_il@data)
# plot(shp_il)
# table(shp_il$COUNTYFP)
shp_cook <- shp_il[shp_il$COUNTYFP=="031",]
# plot(shp_cook)
if(!file.exists("data_maps/tracts_cook_2019.geojson")){
    writeOGR(obj = shp_cook, 
             dsn = "data_maps/tracts_cook_2019.geojson", 
             layer = "tracts", 
             driver = "GeoJSON")
}
str(shp_cook, 2)

## Calculate intersection
shp_cook_wgs84 <- spTransform(shp_cook, CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_ward_wgs84 <- spTransform(shp_ward,  CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_cityoutline_wgs84 <- gUnaryUnion(shp_ward_wgs84)
shp_chicago_wgs84 <- gIntersection(spgeom1 = shp_cook_wgs84,
                                   spgeom2 = shp_cityoutline_wgs84,
                                   byid = TRUE,
                                   id = NULL,
                                   drop_lower_td = TRUE,
                                   unaryUnion_if_byid_false = TRUE,
                                   checkValidity = FALSE)
plot(shp_chicago_wgs84, col='yellow')
plot(shp_cook_wgs84, add=T, col='blue')
plot(shp_ward_wgs84, add=T, col='red')
plot(shp_chicago_wgs84, add=T, col='yellow')

str(shp_cook, 2)
str(shp_chicago_wgs84, 2)

## add data back to new trimmed map
dim(shp_chicago_wgs84@data)
dim(shp_cook@data)

str(shp_chicago_wgs84@polygons[1], 3)
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
         dsn = "data_maps/tracts_2019_chicago.geojson", 
         layer = "tracts", 
         driver = "GeoJSON")

# test
# shp <- readOGR("data_maps/tracts_trimmed.geojson")
# str(shp, 2)


