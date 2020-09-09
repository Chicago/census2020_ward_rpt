
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
ssum <- function(x){sum(x, na.rm = TRUE)}

##==============================================================================
## IMPORT DATA
##==============================================================================

shp_community <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shp_tracts <- readOGR("data_maps/tracts.geojson", stringsAsFactors = FALSE)
shp_wards <- readOGR("data_maps/wards.geojson", stringsAsFactors = FALSE)
shp_city_outline <- gUnaryUnion(as(shp_community, "SpatialPolygons"))

datMailRates <- fread("../2010_U.S._Census_Mail_Return_Rates_and_Demographics_by_Tract.csv")
setnames(datMailRates, tolower(colnames(datMailRates)))
setnames(datMailRates, gsub(" ", "_", colnames(datMailRates)))
datMailRates <- cbind(GEOID = as.character(datMailRates$geographic_identifer),
                      datMailRates) 
datMailRates <- datMailRates[match(shp_tracts@data$GEOID, datMailRates$GEOID)]

htc <- fread("../Census2020/data-census-planning/pdb2017tract_2010MRR_2018ACS_IL.csv")
htc[ , geoidtxt := as.character(geoidtxt)]
htc <- htc[match(shp_tracts@data$GEOID, htc$geoidtxt)]
htc$geoidtxt == shp_tracts$GEOID
htc$geoidtxt == datMailRates$GEOID


## the mising tracts are ohare, midway, and two oddballs
plot(shp_tracts[which(is.na(htc$geoidtxt)),])
shp_tracts[which(is.na(htc$geoidtxt)), ]@data
missing <- shp_tracts[which(is.na(htc$geoidtxt)), "GEOID"]@data

## Subset everythign to the ones that are not missing in the HTC data
# ii <- shp_tracts@data$GEOID %in% htc$geoidtxt
# shp_tracts <- shp_tracts[ii, ]
# datMailRates <- datMailRates[ii]
# htc <- htc[ii]


##==============================================================================
## RELATE CENSUS TRACTS
##==============================================================================
# inin(pop$TRACT, shp_tracts$GEOID)
# inin(pop$TRACT_work, shp_tracts$GEOID)

htc[,1:10,with=F]
inin(htc$geoidtxt, shp_tracts$GEOID)

hist(htc$lowresponsescore)
hist(100 - htc$lowresponsescore)
# quants <- quantile(htc$lowresponsescore, seq(0,1,.05))
# clipper(quants)

hist(datMailRates$total_population, 100, freq = T)

##==============================================================================
## MAP OF RETURN RATES
##==============================================================================

cols_bright <- diverging_hcl(n = 7, h = c(360, 138), c = c(144, 42), l = c(67, 82), power = c(0.45, 1.1))
cols_muted <- diverging_hcl(n = 7, h = c(340, 128), c = c(60, 80), l = c(30, 97), power = c(0.8, 1.5))

# ################################################################################
# ## 2010 MAIL IN RATES
# ################################################################################
ii <- match(shp_tracts$GEOID, datMailRates$GEOID)
vec <- datMailRates$mail_return_rate[ii]
pal <- colorNumeric(palette = cols_muted, domain = vec)
m1 <- leaflet() %>%
    addProviderTiles("Stamen.TonerHybrid") %>%
    addPolygons(data = shp_city_outline, fill = FALSE, color = "black", weight = 3) %>%
    fitBounds(-87.94011, 41.64454, -87.52414, 42.02304) %>%
    addPolygons(data = shp_tracts,
                # fillColor = ~ pal(tgt_mr$N_home_0),
                fillColor = ~ pal(vec),
                fillOpacity = 0.7, weight = 0.5,
                # label = ~ tgt_mr$tract,
                label = ~ vec) %>%
    addLegend(pal = pal,
              values = vec,
              title = "2010 Mail in rates",
              position = "bottomleft")
m1

################################################################################
## 2020 HTC SCORE
################################################################################
ii <- match(shp_tracts$GEOID, htc$geoidtxt)
vec <- 100-htc$lowresponsescore[ii]
pal <- colorNumeric(cols_muted, domain=vec, reverse = !T)
m2 <- leaflet() %>%
    addProviderTiles("Stamen.TonerHybrid") %>% 
    addPolygons(data = shp_city_outline, fill = FALSE, color = "black", weight = 3) %>%
    fitBounds(-87.94011, 41.64454, -87.52414, 42.02304) %>%
    addPolygons(data = shp_tracts,
                # fillColor = ~ pal(tgt_mr$N_home_0),
                fillColor = ~ pal(vec),
                fillOpacity = 0.7, weight = 0.5,
                # label = ~ tgt_mr$tract,
                label = ~ vec) %>%
    addLegend(pal = pal, 
              values = vec, 
              title = "2020 Score",
              position = "bottomleft")
m2

htc[ , ssum((1-lowresponsescore/100) * totpop)/ssum(totpop)]



##==============================================================================
## Import replica data
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

ssum(htc$tothh)

## Household summary:
pophs <- pop[,
             list(.N, household_id, TRACT, lat, lng)]

pophs <- merge(pophs, 
               htc[i = TRUE,
                   list(TRACT = geoidtxt, 
                        resp_score = (1-lowresponsescore/100))],
               order = FALSE)
sum(pophs$N)

## Geocode to ward
res <- geocode_to_map(lat = pophs$lat,
                      lon = pophs$lng,
                      map = shp_wards,
                      map_field_name = "ward")
str(res)
pophs$ward <- as.numeric(res)


wardsummary <- pophs[,list(pop = sum(N),
                           households = .N,
                           est_resp = sum(resp_score) / .N),
                     keyby = ward]
wardsummary
# clipper(wardsummary)
#


## Households to crosswalk:
crosswalk <- pophs[,.N,keyby = list(TRACT, ward)]
crosswalk <- crosswalk[crosswalk[,.(tract_total = sum(N)),keyby=TRACT]]
crosswalk[ , allocation := N / tract_total]
# wtf(crosswalk)

shortnames <- data.table(TRACT = shp_tracts$GEOID, 
                         tract_shortname = shp_tracts$NAME)
# clipper(shortnames)

crosswalk <- merge(crosswalk, shortnames, "TRACT", all.x=T)
setnames(crosswalk, "N", "households")
write.csv(crosswalk, 
          "data_census_planning/crosswalk_replica_based.csv",
          row.names = FALSE)
