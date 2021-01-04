

## FILE FOR CREATING SUMMARY DATA AND READING IN RESPONSE RATE DATA

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
shp_tracts_2020 <- readOGR("data_maps_census_2020/tracts_2020_stuartlynn_Cook.geojson", stringsAsFactors = FALSE)
shp_tracts_2020$GEOID <- substr(shp_tracts_2020$GEO_ID, 10, 20)

shp_centroids <- centroid(shp_community,
                          iterations = 150,
                          initial_width_step = .01)
shp_community$centroid_x <- shp_centroids@coords[,'x']
shp_community$centroid_y <- shp_centroids@coords[,'y']
rm(shp_centroids)

shp_centroids <- centroid(shp_tracts_2020,
                          iterations = 150,
                          initial_width_step = .01)
shp_tracts_2020$centroid_x <- shp_centroids@coords[,'x']
shp_tracts_2020$centroid_y <- shp_centroids@coords[,'y']
rm(shp_centroids)

##------------------------------------------------------------------------------
## Crosswalk based on replica data
##------------------------------------------------------------------------------

to2020 <- fread("data_census_planning/crosswalk_replica_2019_tracts.csv")
to2020[ , TRACT_2020 := sprintf("%06i", as.integer(TRACT_2020))]
to2020[ , TRACT_2019 := sprintf("%06i", as.integer(TRACT_2019))]
to2020 <- to2020[i = TRUE,
                 j = list(TRACT_2020 = TRACT_2020[which.max(allocation)]), 
                 by = TRACT_2019]


toWard <- fread("data_census_planning/crosswalk_replica_based.csv")
toWard[ , TRACT:=substr(TRACT,6,11)]
toWard <- toWard[!is.na(TRACT)]
# toWard <- dcast(toWard, TRACT~ward, value.var = "allocation", fill = 0)

##------------------------------------------------------------------------------
## Locally collected responses for 2020
##------------------------------------------------------------------------------

resp_current <- fread(max(list.files(path = "data_daily_resp_cook/",
                                     pattern = "^cook.+csv$", full.names = T)))
resp_current[ , tract := NULL]
resp_current[ , GEOID := substr(GEO_ID, 10, 20)]
resp_current[ , TRACT := substr(GEO_ID, 15, 20)]
resp_current <- resp_current[match(shp_tracts_2020$TRACT, TRACT)]

##------------------------------------------------------------------------------
## HTC file from CB
## Use cross walk to link to 2020 tracts
##------------------------------------------------------------------------------
# file.copy("../data-census-planning/pdb2019bgv6_us.csv",
#           "data_census_planning/")
htc <- fread("data_census_planning/pdb2019bgv6_us.csv")
htc <- htc[State==17 & County == 31]
htc[ , GIDBG := as.character(GIDBG)]
htc[ , Tract := sprintf("%06i",Tract)]

# table(unique(htc$Tract) %in% to2020$TRACT_prev)
# table(unique(htc$Tract) %in% to2020$TRACT_2020)
htc[ , TRACT_2020 := to2020[match(htc$Tract, TRACT_2019), TRACT_2020]]

table(shp_tracts_2020$TRACT %in% htc$TRACT_2020)
table(htc$TRACT_2020 %in% shp_tracts_2020$TRACT)
table(unique(htc$TRACT_2020) %in% shp_tracts_2020$TRACT)

htc <- htc[htc$TRACT_2020 %in% shp_tracts_2020$TRACT]
dim(htc)

sum(htc$Tot_Population_CEN_2010)
sum(htc$Tot_Population_ACS_13_17)
sum(htc$Tot_Population_ACSMOE_13_17)

sum(htc$Tot_Housing_Units_CEN_2010)
sum(htc$Tot_Housing_Units_ACS_13_17)
sum(htc$Tot_Housing_Units_ACSMOE_13_17)

shp_tracts_2020$community <- geocode_to_map(shp_tracts_2020$centroid_y,
                                            shp_tracts_2020$centroid_x,
                                            map = shp_community,
                                            map_field_name = "community")
htc$community <- shp_tracts_2020$community[match(htc$TRACT_2020, shp_tracts_2020$TRACT)]
resp_current$community <- shp_tracts_2020$community[match(resp_current$TRACT, 
                                                          shp_tracts_2020$TRACT)]

htc_household <- htc[i = TRUE,
                     j = list(households = sum(Tot_Housing_Units_ACS_13_17),
                              Tot_Population_ACS_13_17 = sum(Tot_Population_ACS_13_17),
                              Tot_Occp_Units_ACS_13_17 = sum(Tot_Occp_Units_ACS_13_17),
                              Hispanic_ACS_13_17 = sum(Hispanic_ACS_13_17),
                              pct_hisp = sum(Hispanic_ACS_13_17) / sum(Tot_Population_ACS_13_17)),
                     keyby = list(TRACT = TRACT_2020)]
htc_household
# hist(htc_household$pct_hisp)

resp_community <- merge(resp_current, htc_household, "TRACT")
resp_community
summary_community <- resp_community[i = TRUE,
                                    j = list(response_rate = round(sum(CRRALL * households)/sum(households)/100, 2),
                                             population = sum(Tot_Population_ACS_13_17),
                                             Tot_Occp_Units_ACS_13_17 = sum(Tot_Occp_Units_ACS_13_17),
                                             households = sum(households),
                                             hisp_households = round(sum(pct_hisp * households))),
                                    keyby = community]
summary_community[ , pct_hisp_households := round(hisp_households / households, 2)]
setnames(summary_community, gsub("_"," ",colnames(summary_community)))
summary_community
# clipper(summary_community)




# resp_ward <- merge(resp_current[,-c("GEO_ID", "GEOID")], 
#                    htc_household, 
#                    "TRACT")
# ## note this duplicates tract level data
# resp_ward <- merge(toWard[i = TRUE,
#                           j = list(TRACT,
#                                    ward, 
#                                    households_ward = households,
#                                    households_tract = tract_total,
#                                    allocation)], 
#                    resp_ward, 
#                    by = "TRACT")
# summary_ward <- resp_ward[i = TRUE,
#                           j = list(response_rate = round(sum(CRRALL * households* allocation)/sum(households* allocation)/100, 2),
#                                    population = sum(Tot_Population_ACS_13_17 * allocation),
#                                    Tot_Occp_Units_ACS_13_17 = sum(Tot_Occp_Units_ACS_13_17 * allocation),
#                                    households = sum(households * allocation),
#                                    hisp_households = round(sum(pct_hisp * households * allocation))),
#                           keyby = ward]
# summary_ward[ , pct_hisp_households := round(hisp_households / households, 2)]
# setnames(summary_ward, gsub("_"," ",colnames(summary_ward)))
# summary_ward
# # wtf(summary_ward)
# 
# # clipper(civis_ward_table)
# 
# plot(civis_ward_table$tot_occp_units_acs_13_17, summary_ward$`Tot Occp Units ACS 13 17`)
# sum(civis_ward_table$tot_occp_units_acs_13_17)
# sum(summary_ward$`Tot Occp Units ACS 13 17`)

resp_daily <- rbindlist(lapply(list.files(path = "data_daily_resp_cook/", 
                                          pattern = "^cook.+csv$", full.names = T), 
                               fread))
# resp_daily[ , GEOID := substr(GEO_ID, 10, 20)]
resp_daily[ , TRACT := substr(GEO_ID, 15, 20)]
resp_daily[ , GEO_ID := NULL]
resp_daily[ , tract := NULL]
resp_daily[ , state := NULL]
resp_daily[ , county := NULL]
# resp_daily <- resp_daily[TRACT%in%shp_tracts_2020$TRACT]
resp_daily

dim(htc)
htc[,.N,community]
inin(resp_daily$TRACT, htc$TRACT_2020)
inin(unique(resp_daily$TRACT), unique(htc$TRACT_2020))
inin(unique(resp_daily$TRACT), unique(shp_tracts_2020$TRACT))
inin(unique(htc$TRACT_2020), unique(shp_tracts_2020$TRACT))
inin(unique(htc$TRACT_2020), unique(resp_daily$TRACT))
htc[ , sum(Tot_Housing_Units_ACS_13_17)]
htc[TRACT_2020 %in% shp_tracts_2020$TRACT, sum(Tot_Housing_Units_ACS_13_17)]
htc[TRACT_2020 %in% resp_daily$TRACT, sum(Tot_Housing_Units_ACS_13_17)]

table(is.na(htc[match(resp_daily$TRACT, htc$TRACT_2020) , 
                Tot_Housing_Units_ACS_13_17]))
table(is.na(htc[match(htc$TRACT_2020, resp_daily$TRACT) , 
                Tot_Housing_Units_ACS_13_17]))
resp_daily$Tot_Housing_Units_ACS_13_17 <- htc[match(resp_daily$TRACT, htc$TRACT_2020) , 
                                              Tot_Housing_Units_ACS_13_17]
resp_daily[,sum(Tot_Housing_Units_ACS_13_17, na.rm=T), RESP_DATE]

# ddall <- dcast(resp_daily, TRACT~RESP_DATE, value.var = "DRRALL", 
#                fun.aggregate = function(x)x/100,
#                fill = 0)






