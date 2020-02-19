
library(shiny)
library(leaflet)
library(RColorBrewer)
library(rgdal) #for reading/writing geo files
library(rgeos) #for simplification
library(sp)
library(data.table)

set_project_dir("census2020_ward_rpt")
source("functions/sourceDir.R")
sourceDir("functions")

##------------------------------------------------------------------------------
## Load data
##------------------------------------------------------------------------------

set_project_dir("census2020_ward_rpt")
shp_ward <- readOGR("data_maps/wards.geojson")
shp_community <- readOGR("data_maps/community_areas.geojson")

datMailRates <- as.data.table(readOGR("data_maps/tracts.geojson")@data)

## Pull HTC/LRS data from Excel, order to match tract map, recode 99999 to NA
htc <- openxlsx::read.xlsx("data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx",
                           sheet = 2, startRow = 6)
htc <- as.data.table(htc)
htc <- htc[match(datMailRates$GEOID, htc$GEOIDtxt)]
htc[LowResponseScore == 99999, LowResponseScore := NA]
htc[MailReturnRateCen2010 == 99999, MailReturnRateCen2010 := NA]

shp_community_buf <- gBuffer(shp_community, width = -.00001)
plot(shp_community_buf)
plot(shp_community_buf, add=T, border='blue')

# shp_community %over% shp_ward
# shp_ward[1,] %over% shp_community
# 
# 
# plot(shp_ward[1,])
# plot(shp_community[shp_community$area_num_1==29, ], add=T)
# 
# 
# ii <- over(shp_ward[1,], shp_community, returnList = T)[[1]]$area_num_1
# plot(shp_ward[1,])
# plot(shp_community[shp_community$area_num_1==ii[1], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[2], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[3], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[4], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[5], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[6], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[7], ], add=T)
# plot(shp_community[shp_community$area_num_1==ii[8], ], add=T)

a <- shp_ward[1,]
b <- shp_community[shp_community$area_num_1==31, ]
plot(gIntersection(a, b))
plot(gIntersection(a, b, drop_lower_td = T))

gIntersection(a, gBuffer(b, width = -.000001))

str(a, 2)
gIntersects(a,b)
gIntersects(a,gBuffer(b, width = -.000001))


gOverlaps(a,b)
gOverlaps(shp_ward,b,byid = T, returnDense = T)



