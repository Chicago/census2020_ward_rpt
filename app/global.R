
library(shiny)
library(leaflet)
library(RColorBrewer)
library(rgdal) #for reading/writing geo files
library(rgeos) #for simplification
library(sp)
library(data.table)

source("functions/set_project_dir.R")
set_project_dir("census2020_ward_rpt")
source("functions/sourceDir.R")
sourceDir("functions")

## Steps to read civis data
## For key setup, see https://civisanalytics.github.io/civis-r/
library(civis)
source("config/setkey.R")

##------------------------------------------------------------------------------
## Load data
##------------------------------------------------------------------------------

shp_community <- readOGR("data_maps/community_areas.geojson", stringsAsFactors = FALSE)
shp_tracts <- readOGR("data_maps/tracts_2019_chicago.geojson", stringsAsFactors = FALSE)
shp_wards <- readOGR("data_maps/wards.geojson", stringsAsFactors = FALSE)

#Convert community area names from all caps to capitalized first word. 
shp_community@data$community <- capwords(tolower(shp_community@data$community))

## Create versions with a little room between polygons
## ignore warnings
shp_community_buf <- gBuffer(shp_community, width = -.00001)
shp_tracts_buf <- gBuffer(shp_tracts, width = -.00001)
shp_wards_buf <- gBuffer(shp_wards, width = -.00001)

# ## Note change in classes
# class(shp_tracts)
# class(shp_tracts_buf)

# ## Check for shape
# plot(shp_community)
# plot(shp_community_buf, add=T, border='blue')


## Pull HTC/LRS data from Excel, order to match tract map, recode 99999 to NA
htc <- openxlsx::read.xlsx("data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx",
                           sheet = 2, startRow = 6)
htc <- as.data.table(htc)
htc <- htc[match(shp_tracts$GEOID, htc$GEOIDtxt)]
htc[LowResponseScore == 99999, LowResponseScore := NA]
htc[MailReturnRateCen2010 == 99999, MailReturnRateCen2010 := NA]

## Pull Civis data from Planning database
## -- THIS TAKES A LONG TIME, SEE "SELECTED COLUMN" METHOD BELOW --
# civis_pdb <- read_civis_query("SELECT *
#                               FROM cic.pdb2019trv3_us
#                               WHERE
#                               county=31 AND state=17")
# civis_pdb <- civis_pdb[match(shp_tracts$GEOID, civis_pdb$gidtr)]
# colnames(civis_pdb)

## Pull Civis data from Planning database - selected columns
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

## Civis Ward-tract crosswalk file
crosswalk <- fread("data_census_planning/crosswalk.csv")

## Convert tract to 6 digit string, including leading zeros
crosswalk[ , census_tract := census_tract * 100]
crosswalk[ , census_tract := sprintf("%06i", as.integer(census_tract))]

## Check
table(shp_tracts$TRACTCE %in% crosswalk$census_tract)
# plot(shp_tracts)
# plot(shp_tracts[!shp_tracts$TRACTCE %in% civis_pdb$tract, ], add=T,col="red")
# plot(shp_tracts[!as.numeric(shp_tracts$TRACTCE) %in% civis_pdb$tract, ], add=T,col="blue")


#use the Civis crosswalk file to assign each tract to a ward
#NOTE: There seems to be a problem with this - we lose some rows. Is there a better way to do this?
civis_pdb <- merge(x = civis_pdb,
                   y = crosswalk[,.(tract=census_tract, ward)],
                   by = "tract",
                   sort = F,
                   all.x = TRUE)
# table(civis_pdb$tract %in% crosswalk$census_tract)
# geneorama::NAsummary(civis_pdb)
# 
# str(shp_tracts@data)
# table(civis_pdb$tract %in% shp_tracts$TRACTCE) # F:448 / T:874
# table(shp_tracts$TRACTCE %in% civis_pdb$tract) # T:871
# length(crosswalk$census_tract) # 802
# table(crosswalk$census_tract %in% civis_pdb$tract) # F:1 / T:801
# table(crosswalk$census_tract %in% shp_tracts$TRACTCE) # F:1 / T:801
# table(shp_tracts$TRACTCE %in% crosswalk$census_tract) # F:73 / T:798
# dim(shp_tracts)
# plot(shp_tracts)
# plot(shp_tracts[!shp_tracts$TRACTCE %in% civis_pdb$tract, ], add=T,col="red")
# plot(shp_tracts[!as.numeric(shp_tracts$TRACTCE) %in% civis_pdb$tract, ], add=T,col="blue")

# 
# table(as.numeric(crosswalk$census_tract) %in% as.numeric(civis_pdb$tract))
# table(as.numeric(crosswalk$census_tract) %in% as.numeric(shp_tracts$TRACTCE))
# table(as.numeric(shp_tracts$TRACTCE) %in% as.numeric(crosswalk$census_tract))


## Ward visualization table
# civis_ward <- data.table(read_civis("cic.ward_visualization_table", database="City of Chicago"))
civis_ward_table <- read_civis_query("select * from cic.ward_visualization_table")

## Daily visualization rates
civis_daily_rates <- as.data.table(civis::read_civis("cic.ward_daily_rates_2020", database="City of Chicago"))
# civis_daily_rates[ , .N, keyby=list(ward, response_date)]

civis_daily_rates_tract <- as.data.table(civis::read_civis("public.raw_data_2020", database="City of Chicago"))



