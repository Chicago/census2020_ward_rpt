

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
shp_tracts <- readOGR("data_maps/tracts.geojson", stringsAsFactors = F)
str(shp_tracts, 2)

## Calculate intersection
shp_tracts_wgs84 <- spTransform(shp_tracts, CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_ward_wgs84 <- spTransform(shp_ward,  CRS("+proj=longlat +ellps=WGS84 +no_defs"))
shp_cityoutline_wgs84 <- gUnaryUnion(shp_ward_wgs84)
shp_tracts_wgs84_trimmed <- gIntersection(spgeom1 = shp_tracts_wgs84,
                                          spgeom2 = shp_cityoutline_wgs84,
                                          byid = TRUE,
                                          id = NULL,
                                          drop_lower_td = TRUE,
                                          unaryUnion_if_byid_false = TRUE,
                                          checkValidity = FALSE)
plot(shp_tracts_wgs84_trimmed, col='yellow')
plot(shp_tracts_wgs84, add=T, col='blue')
plot(shp_ward_wgs84, add=T, col='red')
plot(shp_tracts_wgs84_trimmed, add=T, col='yellow')

summary(shp_tracts)
summary(shp_tracts_wgs84_trimmed)

str(shp_tracts, 2)
str(shp_tracts_wgs84_trimmed, 2)

## add data back to new trimmed map
dim(shp_tracts_wgs84_trimmed@data)
dim(shp_tracts@data)

shp_tracts_wgs84_trimmed <- SpatialPolygonsDataFrame(shp_tracts_wgs84_trimmed, 
                                                     data = shp_tracts@data,
                                                     match.ID = FALSE)
str(shp_tracts_wgs84_trimmed@data)

writeOGR(obj = shp_tracts_wgs84_trimmed, 
         dsn = "data_maps/tracts_trimmed.geojson", 
         layer = "tracts", 
         driver = "GeoJSON")

# test
# shp <- readOGR("data_maps/tracts_trimmed.geojson")
# str(shp, 2)


