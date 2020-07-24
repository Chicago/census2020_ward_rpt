

##==============================================================================
## INITIALIZE
##==============================================================================

rm(list=ls())

library(geneorama)
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
## DOWNLOAD DATA
##==============================================================================


shpCommunity <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shpTracts <- readOGR("data_maps/tracts.geojson", stringsAsFactors = FALSE)
# shp_wards <- readOGR("data_maps/wards.geojson", stringsAsFactors = FALSE)
shpOutline <- gUnaryUnion(as(shpCommunity, "SpatialPolygons"))

shpTracts <- readOGR("data_maps_census_2020/tracts_2020_stuartlynn_Chicago.geojson")
resp <- fread("data_daily_resp_cook/cook 2020-07-09.csv")

library(tmap)
tmap_mode(c("plot","view")[1])

ii <- match(shpTracts$GEO_ID, resp$GEO_ID)
shpTracts$`Response Rate` <- resp[ii, CRRALL]

tm_shape(shpTracts[!is.na(shpTracts$`Response Rate`), ], is.master = TRUE) + 
  tm_polygons("Response Rate",
              # palette = list("YlOrRd"),
              # palette = "RdYlGn",
              palette = "RdYlBu",
              alpha = .7,
              
              id = "GEO_ID") +
  # tm_borders(shpOutline) +
  tm_view(view.legend.position = c("left", "bottom"), ) 
