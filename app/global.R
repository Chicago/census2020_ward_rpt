
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

##------------------------------------------------------------------------------
## Load data
##------------------------------------------------------------------------------

set_project_dir("census2020_ward_rpt")

shp_community <- readOGR("data_maps/community_areas.geojson")
shp_tracts <- readOGR("data_maps/tracts.geojson")
shp_wards <- readOGR("data_maps/wards.geojson")

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

#Pull Civis data - need to make sure API is set up separately. See https://civisanalytics.github.io/civis-r/
library(civis)
civistable <- "cic.pdb2019trv3_us"
civisdata <- read_civis(civistable, database="City of Chicago") #this will take a minute or two
civisdata <- as.data.table(civisdata)
civisdata <- civisdata[match(shp_tracts$GEOID, civisdata$gidtr)]



