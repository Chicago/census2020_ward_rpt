
## Save local copy of source files that are slow to load in R


##==============================================================================
## INITIALIZE
##==============================================================================
rm(list = ls())

library(rgdal)

##------------------------------------------------------------------------------
## Shape files
##------------------------------------------------------------------------------

shp_tracts_2020 <- readOGR("data_maps/tracts_2020_stuartlynn_Chicago.geojson", stringsAsFactors = FALSE)
shp_tracts_prev <- readOGR("data_maps/tracts_2019_chicago.geojson", stringsAsFactors = FALSE)

saveRDS(shp_tracts_2020, "model_2020_response/shp_tracts_2020.Rds")
saveRDS(shp_tracts_prev, "model_2020_response/shp_tracts_prev.Rds")

