
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
## IMPORT DATA
##==============================================================================

shp_community <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shp_tracts_prev <- readOGR("data_maps/tracts.geojson", stringsAsFactors = FALSE)
shp_tracts_2020 <- readOGR("data_maps/tracts_2020_stuartlynn_Chicago.geojson", stringsAsFactors = FALSE)
shp_wards <- readOGR("data_maps/wards.geojson", stringsAsFactors = FALSE)

str(shp_tracts_prev@data)
str(shp_tracts_2020@data)

shp_tracts_2020@data$GEOID <- substr(shp_tracts_2020@data$GEO_ID, 10, 20)

head(shp_tracts_2020@data)

htc <- fread("../data-census-planning/pdb2017tract_2010MRR_2018ACS_IL.csv")
htc[ , geoidtxt := as.character(geoidtxt)]
table(htc$geoidtxt %in% shp_tracts_2020@data$GEOID)
table(htc$geoidtxt %in% shp_tracts_prev@data$GEOID)

##==============================================================================
## Import replica data 
## This is simulated person level data 
## (not real, but statistically similar to real in aggregate)
## Note, this data is not in the repository
##==============================================================================

pop <- data.table()
pop$household_id <- readRDS('../data-replica/downloads/population_cols_chi/01_household_id.Rds')
pop$GEOID <- readRDS('../data-replica/downloads/population_cols_chi/02_GEOID.Rds')
pop$BLOCKID10 <- readRDS('../data-replica/downloads/population_cols_chi/30_BLOCKID10.Rds')
# pop$BLOCKGROUP <- readRDS('../data-replica/downloads/population_cols_chi/31_BLOCKGROUP.Rds')
pop$TRACT <- readRDS('../data-replica/downloads/population_cols_chi/32_TRACT.Rds')
pop$lat <- readRDS('../data-replica/downloads/population_cols_chi/28_lat.Rds')
pop$lng <- readRDS('../data-replica/downloads/population_cols_chi/29_lng.Rds')
# # pop$serial_number <- readRDS('../data-replica/downloads/population_cols_chi/03_serial_number.Rds')
pop$housing_unit_id <- readRDS('../data-replica/downloads/population_cols_chi/27_housing_unit_id.Rds')
pop$workplace_unit_id <- readRDS('../data-replica/downloads/population_cols_chi/33_workplace_unit_id.Rds')
pop$lat_work <- readRDS('../data-replica/downloads/population_cols_chi/34_lat_work.Rds')
pop$lng_work <- readRDS('../data-replica/downloads/population_cols_chi/35_lng_work.Rds')


### Number of households according to HTC data: 1028632
ssum(htc$tothh)

##------------------------------------------------------------------------------
## Aggregate person data to households
##------------------------------------------------------------------------------
pophs <- pop[i= TRUE,
             list(.N),
             list(household_id, TRACT, lat, lng)]
nrow(pophs)

## Merge in low response score (based on tract)
pophs <- merge(pophs, 
               htc[i = TRUE,
                   list(TRACT = geoidtxt, 
                        resp_score = (1-lowresponsescore/100))],
               all.x = TRUE,
               order = FALSE)
sum(pophs$N)    ## 2,709,425
nrow(pophs)     ## 1,173,009
ssum(htc$tothh) ## 1,055,690

##------------------------------------------------------------------------------
## Geocode to ward
##------------------------------------------------------------------------------
res <- geocode_to_map(lat = pophs$lat,
                      lon = pophs$lng,
                      map = shp_wards,
                      map_field_name = "ward")
str(res)
pophs$ward <- as.numeric(res)

##------------------------------------------------------------------------------
## Quick Ward level summary 
##------------------------------------------------------------------------------
wardsummary <- pophs[i= TRUE,
                     j = list(pop = sum(N),
                              households = .N,
                              est_resp = ssum(resp_score) / .N),
                     keyby = ward]
wardsummary
wardsummary[,sum(pop)]
wardsummary[,sum(households)]

##------------------------------------------------------------------------------
## Geocode households to 2020 tract
##------------------------------------------------------------------------------
head(shp_tracts_2020@data)
head(pophs)
res <- geocode_to_map(lat = pophs$lat,
                      lon = pophs$lng,
                      map = shp_tracts_2020,
                      map_field_name = "GEOID")
str(res)
pophs$TRACT_2020 <- res

## After all that, the difference in tracts is tiny
pophs[,.N,list(TRACT==TRACT_2020)]
# > pophs[,.N,list(TRACT==TRACT_2020)]
#    TRACT       N
# 1:  TRUE 1137936
# 2: FALSE    1506
# 3:    NA      89

##------------------------------------------------------------------------------
## Geocode households to Previous Tract data (probably 2019, but I'm not sure)
##------------------------------------------------------------------------------
head(shp_tracts_prev@data)
head(pophs)
res <- geocode_to_map(lat = pophs$lat,
                      lon = pophs$lng,
                      map = shp_tracts_prev,
                      map_field_name = "GEOID")
str(res)
pophs$TRACT_prev <- res

## After all that, the difference in tracts is tiny
pophs[,.N,list(TRACT_prev==TRACT_2020)]
# > pophs[,.N,list(TRACT_prev==TRACT_2020)]
#    TRACT_prev       N
# 1:       TRUE 1138273
# 2:      FALSE   33947
# 3:         NA      89

##------------------------------------------------------------------------------
## Summarize Households by tract and ward to create crosswalk:
##------------------------------------------------------------------------------
crosswalk <- pophs[ , .N, keyby = list(TRACT=TRACT_2020, ward)]
crosswalk <- crosswalk[crosswalk[,.(tract_total = sum(N)),keyby=TRACT]]
crosswalk[ , allocation := N / tract_total]
# wtf(crosswalk)

## Pull out the short names, 
shortnames <- data.table(TRACT = shp_tracts_2020$GEOID, 
                         tract_shortname = shp_tracts_2020$NAME)
# > shortnames
#          TRACT tract_shortname
# 1: 17031820502         8205.02
# 2: 17031380200            3802
# 3: 17031611500            6115
# 4: 17031811100            8111
# 5: 17031711100            7111

crosswalk <- merge(crosswalk, shortnames, "TRACT", all.x=T)
setnames(crosswalk, "N", "households")
write.csv(crosswalk, 
          "data_census_planning/crosswalk_replica_based.csv",
          row.names = FALSE)
