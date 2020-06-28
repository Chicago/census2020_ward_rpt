
rm(list=ls())

library(shiny)
library(leaflet)
library(RColorBrewer)
library(rgdal) #for reading/writing geo files
library(rgeos) #for simplification
library(sp)
library(data.table)

source("functions/sourceDir.R")
sourceDir("functions")

## Steps to read civis data
## For key setup, see https://civisanalytics.github.io/civis-r/
library(civis)
source("config/setkey.R")

##------------------------------------------------------------------------------
## Shape files
##------------------------------------------------------------------------------

shp_community <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shp_tracts_2020 <- readOGR("data_maps_census_2020/tracts_2020_stuartlynn_Chicago.geojson", stringsAsFactors = FALSE)
shp_tracts_prev <- readOGR("data_maps/tracts_2019_chicago.geojson", stringsAsFactors = FALSE)
shp_wards <- readOGR("data_maps/wards.geojson", stringsAsFactors = FALSE)

shp_tracts_2020$GEOID <- substr(shp_tracts_2020$GEO_ID, 10, 20)

shp_tracts_2020_centroids <- centroid(shp_tracts_2020,
                                      iterations = 150,
                                      initial_width_step = .01)
shp_ward_centroids <- centroid(shp_wards,
                               iterations = 150,
                               initial_width_step = .01)

##------------------------------------------------------------------------------
## Crosswalk based on replica data
##------------------------------------------------------------------------------

to2020 <- fread("data_census_planning/crosswalk_to_2020.csv")
to2020[ , TRACT_2020 := as.character(TRACT_2020)]
to2020[ , TRACT_prev := as.character(TRACT_prev)]
to2020 <- to2020[ , list(TRACT_2020=TRACT_2020[which.max(allocation)]), TRACT_prev]

##------------------------------------------------------------------------------
## Locally collected responses for 2020
##------------------------------------------------------------------------------

resp_files <- list.files(path = "data_daily_resp_cook/", pattern = "^cook.+csv$", full.names = T)
resp <- rbindlist(lapply(resp_files, fread))
resp[ , tract := NULL]
resp[ , GEOID := substr(GEO_ID, 10, 20)]
resp[ , TRACT := substr(GEO_ID, 15, 20)]

table(shp_tracts_2020$TRACT %in% resp$TRACT)
table(shp_tracts_prev$TRACTCE %in% resp$TRACT)

resp_current <- resp[RESP_DATE == max(RESP_DATE)]
resp_current <- resp_current[match(shp_tracts_2020$TRACT, TRACT)]

##------------------------------------------------------------------------------
## HTC file from CB
## Use cross walk to link to 2020 tracts
##------------------------------------------------------------------------------
htcfile <- "data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx"
htc <- openxlsx::read.xlsx(htcfile, sheet = 2, startRow = 6)
htc <- as.data.table(htc)
htc[LowResponseScore == 99999, LowResponseScore := NA]
htc[MailReturnRateCen2010 == 99999, MailReturnRateCen2010 := NA]
table(is.na(match(htc$GEOIDtxt, to2020$TRACT_prev)))
htc[ , TRACT_2020 := to2020[match(htc$GEOIDtxt, TRACT_prev), TRACT_2020]]

if(FALSE){
  htc_current_resp <- htc[match(resp_current$GEOID, htc$TRACT_2020)]
  
  ## Based on total household / 2020 tracts
  ssum(resp_current[ , CRRALL] * htc_current_resp$TotHH) / ssum(htc_current_resp$TotHH)
  ssum(resp_current[ , DRRALL] * htc_current_resp$TotHH) / ssum(htc_current_resp$TotHH)
  
  ## Cook County by itself
  url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=county:031&in=state:17"
  census_getter(url)
  census_getter_cook()
}

##------------------------------------------------------------------------------
## Civis data
## PDB table is planning database table
##------------------------------------------------------------------------------

civis_pdb <- read_civis_query("SELECT gidtr, state, state_name, county,
                              county_name, tract, flag, num_bgs_in_tract,
                              land_area, aian_land,
                              mailback_area_count_cen_2010,
                              tea_mail_out_mail_back_cen_2010,
                              tea_update_leave_cen_2010,
                              census_mail_returns_cen_2010,
                              vacants_cen_2010, deletes_cen_2010,
                              census_uaa_cen_2010,
                              valid_mailback_count_cen_2010,
                              frst_frms_cen_2010, rplcmnt_frms_cen_2010,
                              bilq_mailout_count_cen_2010, bilq_frms_cen_2010,
                              mail_return_rate_cen_2010, low_response_score,
                              self_response_rate_acs_13_17,
                              self_response_rate_acsmoe_13_17,
                              tot_population_cen_2010, 
                              nh_blk_alone_acs_13_17, 
                              hispanic_acs_13_17, 
                              tot_housing_units_cen_2010, 
                              eng_vw_acs_13_17
                              FROM cic.pdb2019trv3_us
                              WHERE
                              county=31 AND state=17")

## Create the weighted response value
civis_pdb[ , handicap := low_response_score / mean(low_response_score, na.rm=T)]
civis_pdb[ , weightedresponse := mail_return_rate_cen_2010 * handicap]

## Add back leading zeros to tract numbers
## Check result with: table(nchar(civis_pdb$tract))
civis_pdb[ , tract := sprintf("%06i", as.integer(tract))]

##------------------------------------------------------------------------------
## Civis data 
## Ward table, daily rates by ward, daily rates by tract
##------------------------------------------------------------------------------

## Ward table
civis_tract_table <- read_civis_query("select * from cic.visualization_table")

## Ward table
civis_ward_table <- read_civis_query("select * from cic.ward_visualization_table")

## Daily visualization rates
civis_daily_rates <- read_civis_query("select * from cic.ward_daily_rates_2020")
# str(civis_daily_rates)
civis_daily_rates <- rbindlist(list(civis_daily_rates,
                                    data.table(ward=1:50, response_date = "2020-03-15", response_rate=0)),
                               use.names = TRUE)
civis_daily_rates <- civis_daily_rates[i = TRUE,
                                       j = list(response_rate), 
                                       keyby = list(ward = as.factor(ward), 
                                                    response_date = as.IDate(response_date))]
# civis_daily_rates[ , .N, keyby=list(ward, response_date)]

civis_daily_rates_tract <- read_civis_query("select * from public.raw_data_2020")

cachename <- paste0("WardReport_v2/cache/", Sys.Date(), ".RData")
save.image(file=cachename)



