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
library(magrittr)

##==============================================================================
## IMPORT SHAPE FILES
##==============================================================================

data("chi_community_areas")
data("chi_wards_2015")
data("chi_zip_codes")

data("cook_dupage_tracts_2019")
shp_cook_2019 <- cook_dupage_tracts_2019[cook_dupage_tracts_2019$COUNTYFP=="031", ]
rm(cook_dupage_tracts_2019)

## Create city outline from community areas
shp_city_outline <- gUnaryUnion(as(chi_community_areas, "SpatialPolygons"))

## IMPORT 2020
shp_il_2020 <- readOGR("../Census2020/data-shapefiles/data-tracts-census-2020/tracts_2020_stuartlynn_IL.geojson", 
                       stringsAsFactors = FALSE)
shp_cook_2020 <- shp_il_2020[shp_il_2020@data$COUNTY == "031", ]

## ADD COLORS TO COMMUNITY AREA MAP
# devtools::install_github("hunzikp/MapColoring")
chi_community_areas$col <- colorspace::qualitative_hcl(n = 4, h = c(26, -264), c = 70, l = 70)[
  MapColoring::getColoring(chi_community_areas)]

##==============================================================================
## IMPORT POPULATION DATA
## This is simulated person level data, with household attributes
## (it is *not* real, but statistically valid in aggregate)
## **Note, this data is not in the repository**
##==============================================================================

people_locs <- data.table(
  readRDS('../Census2020/data-replica/downloads/population_cols/28_lat.Rds'),
  readRDS('../Census2020/data-replica/downloads/population_cols/29_lng.Rds'))
hh <- people_locs[ , list(pop=.N), list(lat,lng)]
hh

##==============================================================================
## GEOCODE
##==============================================================================
hh$community <- geocode_to_map(hh$lat, hh$lng, chi_community_areas, "community")
hh$ward <- geocode_to_map(hh$lat, hh$lng, chi_wards_2015, "ward")
hh$zip <- geocode_to_map(hh$lat, hh$lng, chi_zip_codes, "zip")
hh$TRACT_2019 <- geocode_to_map(hh$lat, hh$lng, shp_cook_2019, "TRACTCE")
hh$TRACT_2020 <- geocode_to_map(hh$lat, hh$lng, shp_cook_2020, "TRACT")

hh
NAsummary(hh)

if(FALSE){
  ## CHECK NA VALUES FOR TRACTS
  leaflet() %>%
    addPolygons(data = chi_community_areas, fill = T, color = "black",
                label=~community,
                fillColor = ~col,
                weight = 1, fillOpacity = 1) %>%
    addCircles(data = hh[sample(1:hh[,.N], 10000)],
               color = ~ifelse(is.na(TRACT_2019), "red", "black"),
               lat=~lat, lng=~lng)
}

## No need to keep the non cook values
hh <- hh[!is.na(TRACT_2020)]
NAsummary(hh)
hh


##==============================================================================
## CALCULATE PREVIOUS TRACT CROSSWALK
##==============================================================================
crosswalk_ct_to_2020 <- hh[ , list(pop=sum(pop)), keyby = list(TRACT_2019, TRACT_2020)]
crosswalk_ct_to_2020 <- crosswalk_ct_to_2020[crosswalk_ct_to_2020[,.(tract_total_pop = sum(pop)),keyby=TRACT_2019]]
crosswalk_ct_to_2020[ , allocation := round(pop / tract_total_pop, 3)]

## Loop example:
crosswalk_ct_to_2020[grep("32010.", TRACT_2020)]
crosswalk_ct_to_2020[grep("32010.", TRACT_2019)]

##==============================================================================
## WRITE 2019 TO 2020 TRACT CROSSWALK 
##==============================================================================
cw_tr_outfile <- "data_census_planning/crosswalk_replica_2019_tracts.csv"
fwrite(crosswalk_ct_to_2020, cw_tr_outfile)
fread("data_census_planning/crosswalk_replica_based.csv")

##==============================================================================
## CALCULATE COMMUNITY AERA CROSSWALK
##==============================================================================
crosswalk_ca <- hh[ , list(pop=sum(pop)), keyby = list(TRACT=TRACT_2020, community)]
crosswalk_ca <- crosswalk_ca[crosswalk_ca[,.(tract_total_pop = sum(pop)),keyby=TRACT]]
crosswalk_ca[ , allocation := round(pop / tract_total_pop, 1)]

crosswalk_ca <- crosswalk_ca[order(TRACT, -allocation)]
crosswalk_ca_FINAL <- crosswalk_ca[i = TRUE,
                                   j = list(community = community[1]),
                                   by = TRACT]
## ADD TO TRACT MAP
ii <- match(shp_cook_2020$TRACT, crosswalk_ca_FINAL$TRACT)
shp_cook_2020$community <- crosswalk_ca_FINAL[ii, community]


## CHECK RESULTS AND MAPS
if(FALSE){
  ## EXAMINE TRACTS THAT DON'T GO INTO ONE CA
  hist(crosswalk_ca$allocation)
  crosswalk_ca[,.N,keyby=allocation]
  mixed_tracts <- crosswalk_ca[allocation>.1 & allocation!=1]
  # > mixed_tracts
  #     TRACT    community  pop tract_total_pop allocation
  # 1: 770902         <NA> 3232            3534        0.9
  # 2: 810400         <NA> 4895            6302        0.8
  # 3: 810400 NORWOOD PARK 1407            6302        0.2
  # 4: 831000 LOGAN SQUARE 1305            2196        0.6
  # 5: 831000    WEST TOWN  891            2196        0.4
  # 6: 843900  SOUTH SHORE 1927            3263        0.6
  # 7: 843900     WOODLAWN 1336            3263        0.4
  # 8: 980000        OHARE 1330            1541        0.9
  shp_mixed <- shp_cook_2020[shp_cook_2020$TRACT %in% mixed_tracts$TRACT, ]
  shp_mixed$allocation <- mixed_tracts[match(shp_mixed$TRACT, TRACT), allocation]
  # b <- chi_community_areas[chi_community_areas$community=="NORWOOD PARK",] %>%
  #   bbox %>% as.vector %>% as.list %$% c(.[[1]], .[[2]], .[[3]], .[[4]])
  leaflet() %>% 
    addProviderTiles(providers$CartoDB.Positron) %>% 
    addPolygons(data = shp_cook_2020, weight = .3, fillOpacity = .5, fill = T, 
                fillColor = "black", color = "blue") %>%
    addPolygons(data = chi_community_areas, fill = T, color = "black",
                label=~community,
                fillColor = ~col,
                weight = 1, fillOpacity = .5) %>% 
    addPolygons(data = shp_mixed, weight = 3, fillOpacity = .8, fill = T, 
                color = "red", 
                label=~paste(TRACT,allocation),
                # fillColor = ~colorNumeric(viridisLite::inferno, allocation),
                fillColor = "yellow") 
    # addCircles(data = hh[sample(1:hh[,.N], 10000)],
    #            color = ~ifelse(is.na(TRACT_2019), "red", "black"),
    #            lat=~lat, lng=~lng) 
  # fitBounds(b[1], b[2], b[3], b[4])
  
  ## CHECK RESULTS:
  crosswalk_ca_FINAL[TRACT %in% mixed_tracts$TRACT]
  crosswalk_ca[TRACT=="770902"]
  crosswalk_ca[TRACT=="810400"]
  crosswalk_ca[TRACT=="831000"]
  crosswalk_ca[TRACT=="843900"]
  crosswalk_ca[TRACT=="980000"]
}

##==============================================================================
## CALCULATE WARD CROSSWALK
##==============================================================================
crosswalk_w <- hh[ , list(pop=sum(pop)), keyby = list(TRACT=TRACT_2020, ward)]
crosswalk_w <- crosswalk_w[crosswalk_w[,.(tract_total_pop = sum(pop)),keyby=TRACT]]
crosswalk_w[ , allocation := round(pop / tract_total_pop, 1)]

crosswalk_w <- crosswalk_w[order(TRACT, -allocation)]
crosswalk_w_FINAL <- crosswalk_w[i = TRUE,
                                 j = list(ward = ward[1]),
                                 by = TRACT]
## ADD TO TRACT MAP
ii <- match(shp_cook_2020$TRACT, crosswalk_w_FINAL$TRACT)
shp_cook_2020$ward <- crosswalk_w_FINAL[ii, ward]

##==============================================================================
## CALCULATE ZIP CROSSWALK
##==============================================================================
crosswalk_z <- hh[ , list(pop=sum(pop)), keyby = list(TRACT=TRACT_2020, zip)]
crosswalk_z <- crosswalk_z[crosswalk_z[,.(tract_total_pop = sum(pop)),keyby=TRACT]]
crosswalk_z[ , allocation := round(pop / tract_total_pop, 1)]

crosswalk_z <- crosswalk_z[order(TRACT, -allocation)]
crosswalk_z_FINAL <- crosswalk_z[i = TRUE,
                                 j = list(zip = zip[1]),
                                 by = TRACT]
## ADD TO TRACT MAP
ii <- match(shp_cook_2020$TRACT, crosswalk_z_FINAL$TRACT)
shp_cook_2020$zip <- crosswalk_z_FINAL[ii, zip]


centroids <- centroid(shp_cook_2020, iterations = 150, initial_width_step = .01)
shp_cook_2020$lat_centroid <- unname(centroids@coords[ , 2])
shp_cook_2020$lon_centroid <- unname(centroids@coords[ , 1])
str(shp_cook_2020@data)

##==============================================================================
## WRITE RESULTS
##==============================================================================

fname_cook_jsn <- "data_maps_census_2020/tracts_2020_stuartlynn_Cook.geojson"
fname_cook_rds <- "data_maps_census_2020/tracts_2020_stuartlynn_Cook.Rds"
file.remove(fname_cook_jsn)
writeOGR(obj = shp_cook_2020,  dsn = fname_cook_jsn, layer = "tracts",  driver = "GeoJSON")
saveRDS(shp_cook_2020, file = fname_cook_rds)

