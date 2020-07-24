
rm(list=ls())

##------------------------------------------------------------------------------
## INITIALIZATION
##------------------------------------------------------------------------------
library(data.table)

## Steps to read civis data
## For key setup, see https://civisanalytics.github.io/civis-r/
library(civis)

## Set the Civis key
Sys.setenv(CIVIS_API_KEY=yaml::read_yaml("config/civis_api_key.yaml")$key)


##------------------------------------------------------------------------------
## Read from civis & crosswalk
##------------------------------------------------------------------------------
q_cook <- "SELECT tract FROM cic.pdb2019trv3_us WHERE county=31 AND state=17"
q_all <- "SELECT tract, state, county FROM cic.pdb2019trv3_us"
ex_cook <- data.table(read_civis(sql(q_cook), database = "City of Chicago"))
ex_all <- data.table(read_civis(sql(q_all), database = "City of Chicago"))

cw <- fread("data_census_planning/crosswalk.csv")
cw[ , census_tract := census_tract * 100]

##------------------------------------------------------------------------------
## read tract shape file
##------------------------------------------------------------------------------

shp_tracts_2020 <- readOGR("data_maps_census_2020/tracts_2020_stuartlynn_Chicago.geojson", stringsAsFactors = FALSE)
shp_tracts_prev <- readOGR("data_maps/tracts_2019_chicago.geojson", stringsAsFactors = FALSE)

##------------------------------------------------------------------------------
## Tables
##------------------------------------------------------------------------------
table(ex_cook$tract %in% cw$census_tract)
table(ex_all$tract %in% cw$census_tract)
ex_all[ex_all$tract %in% cw$census_tract]

head(ex_cook$tract)
head(cw$census_tract)

##------------------------------------------------------------------------------
## Map
##------------------------------------------------------------------------------

par(mfrow=c(1,2))

plot(shp_tracts_2020)
plot(shp_tracts_2020[!shp_tracts_2020$TRACT %in% ex_all$tract, ], add=T, col="red")


plot(shp_tracts_prev)
plot(shp_tracts_prev[!shp_tracts_prev$TRACTCE %in% ex_cook$tract, ], add=T, col="red")


