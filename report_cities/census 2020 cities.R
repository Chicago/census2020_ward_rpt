rm(list=ls())

# library(shiny)
# library(leaflet)
# library(RColorBrewer)
# library(rgdal) #for reading/writing geo files
# library(rgeos) #for simplification
# library(sp)

library(data.table)
library(censusapi)

source("functions/sourceDir.R")
sourceDir("functions")

##------------------------------------------------------------------------------
## GET / SET CENSUS KEY
##------------------------------------------------------------------------------

Sys.setenv(CENSUS_KEY=yaml::read_yaml("config/census_api_key.yaml")$census_api_key)
Sys.getenv("CENSUS_KEY")

censuskey <- yaml::read_yaml("config/census_api_key.yaml")$census_api_key

##------------------------------------------------------------------------------
## URL FOR EXAMPLE CALLS
##------------------------------------------------------------------------------

# https://hrecht.github.io/censusapi/articles/example-masterlist.html#decennial-census-self-response-rates
# https://hrecht.github.io/censusapi/articles/

##------------------------------------------------------------------------------
## 2010 POPULATIONS
##------------------------------------------------------------------------------

# geos <- listCensusMetadata(name = "dec/sf1", vintage = 2010, type = "geographies", group = "P1")
# geos2 <- geos[, 1:3]
# wtf(geos2)

str(geos,1)
listCensusMetadata(name = "dec/sf1", vintage = 2010, type = "variables", group = "P2")
data2010 <- getCensus(name = "dec/sf1",
                      vintage = 2010,
                      vars = c("NAME", "P001001", "H010001"),
                      region = "place:*")
str(data2010)
data2010 <- data.table(data2010)
data2010[order(-H010001)]
# wtf(data2010)
head(data2010)

##------------------------------------------------------------------------------
## PLANNING DATABASE FOR COOK
##------------------------------------------------------------------------------
pdb_meta <- data.table(listCensusMetadata(name = "pdb/blockgroup", vintage = 2018, type = "variables"))
pdb_meta
# wtf(pdb_meta)
pdb <- getCensus(name = "pdb/blockgroup",
                 vintage = 2018,
                 vars = c("GIDBG", #State/County/Tract/BG - A 12 digit code. The first two digits denote State, the next three digits denote County, the next six digits denote Tract, and the last digit denotes Block Group.
                          "County_name", 
                          "State_name", 
                          "Tot_Population_CEN_2010", # Total population in the 2010 Census
                          "Tot_Housing_Units_ACSMOE_12_16", # MOE - Total Housing Units
                          "Tot_Housing_Units_CEN_2010", # Total Housing Units in the 2010 Census
                          "Low_Response_Score", # Prediction of low census mail return rate
                          "Flag", # Block Group area with block group code 0 (zero), representing areas that are not habitable
                          "Vacants_CEN_2010", # Number of 2010 Census mail forms where unit confirmed vacant
                          "Tot_Vacant_Units_CEN_2010", # Total vacant Housing Units in the 2010 Census
                          "pct_Deletes_CEN_2010", # Percentage calculated by dividing Deletes_CEN_2010 by MailBack_Area_Count_CEN_2010
                          "Census_UAA_CEN_2010", # Number of 2010 Census mail forms as undeliverable as addressed
                          "pct_Census_Mail_Returns_CEN_2010", # Percentage calculated by dividing Census_Mail_Returns_CEN_2010 by MailBack_Area_Count_CEN_2010
                          "Mail_Return_Rate_CEN_2010"), # 2010 Census Mail Return Rate
                 region = "block group:*",
                 regionin = "state:17+county:031")
# wtf(pdb)
head(pdb)

##------------------------------------------------------------------------------
## MOST? PLACES
##------------------------------------------------------------------------------
url <- "https://api.census.gov/data/2018/acs/acs1?get=B00001_001E,NAME&for=place:*"
# places <- census_getter(url)
places <- httr::GET(url = url) %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON() %>%
    data.frame(stringsAsFactors = F)
places <- setnames(data.table(places[-1, ]), unlist(places[1, ]))
places
str(places)
places[grep("Chicago", NAME)]

##------------------------------------------------------------------------------
## 2020 RESPONSE RATE FOR PLACES
##------------------------------------------------------------------------------
# il_place_responses <- getCensus(
#     name = "dec/responserate",
#     vintage = 2020,
#     vars = c("NAME", "RESP_DATE", "CRRALL", "CRRINT"),
#     region = "place:*",
#     regionin = "state:17")
# il_place_responses
# il_place_responses[grep("Chicago", il_place_responses$NAME),]

place_responses <- getCensus(
    name = "dec/responserate",
    vintage = 2020,
    vars = c("NAME", "RESP_DATE", "CRRALL", "CRRINT"),
    region = "place:*",
    regionin = "state:*")
place_responses <- data.table(place_responses)
# wtf(place_responses)
place_responses

str(places)
place_responses_merged <- merge(place_responses, 
                                places,
                                key = c("state", "place"),
                                all.x = TRUE)
place_responses_merged <- merge(place_responses_merged, 
                                data2010,
                                key = c("state", "place"),
                                all.x = TRUE)

place_responses_merged
# wtf(place_responses_merged)
place_responses_merged


## Example from using the ACS pacakge:
# api.key.install(censuskey)

## Individual steps used to develop function
# http_response <- httr::GET(url = "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=state:*")
# 
# # str(http_response)
# # http_response$content
# resp_text <- httr::content(http_response, as = "text", encoding = "UTF-8")
# resp <- jsonlite::fromJSON(resp_text)
# resp_dt <- data.table(resp[-1, ], stringsAsFactors = F)
# setnames(resp_dt, resp[1, ])
# fwrite(resp_dt, tf)
# resp_dt <- fread(tf)
# str(resp_dt)
# file.remove(tf)
# rm(tf)


# ## Example of all 50 states
# census_getter("https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=state:*")
# 
# ## Cook County by itself
# url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=county:031&in=state:17"
# census_getter(url)
# 
# ## All census tracts in Cook County
# url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=tract:*&in=state:17%20county:031&key=60179a2964868d80e37ab0d49e88e654dedf0bc5"
# census_getter(url)
# 
# ## All census tracts in Cook County with yaml key
# url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=tract:*&in=state:17%20county:031&key=APIKEY"
# url <- gsub("APIKEY", censuskey, url)
# census_getter(url)
# 
# ## All census tracts in Cook County by components
# baseurl <- "https://api.census.gov/data/2020/dec/responserate?"
# parts <- list("get=GEO_ID,RESP_DATE,DRRALL,CRRALL,DRRINT,CRRINT",
#               "for=tract:*",
#               "in=state:17%20county:031",
#               "key=APIKEY")
# url <- paste0(baseurl, paste(parts, collapse = "&"))
# url <- gsub("APIKEY", censuskey, url)
# census_getter(url)
# 
# ## All census tracts in Cook County by components
# ## All dates
# baseurl <- "https://api.census.gov/data/2020/dec/responserate?"
# parts <- list("get=DRRALL,CRRINT,CRRALL,GEO_ID,DRRINT",
#               "RESP_DATE:2020-03-22",
#               "for=tract:*",
#               "in=state:17%20county:031",
#               "key=APIKEY")
# url <- paste0(baseurl, paste(parts, collapse = "&"))
# url <- gsub("APIKEY", censuskey, url)
# census_getter(url)

# 
# get_post <- function(params, patient_file_loc, tok){
#     
#     ## Format the token into the authorization string
#     auth_str <- paste("Bearer", tok)
#     
#     ## POST record to API
#     http_response <- httr::POST(url = params$api_endpoint, 
#                                 body = httr::upload_file(patient_file_loc), 
#                                 encode = "json",
#                                 httr::add_headers(Authorization = auth_str))
#     
#     ## ID FOR LOOKING UP POST IN ORACLE
#     post_id <- basename(httr::headers(http_response)$`content-location`)
#     resp_text <- httr::content(http_response, as = "text", encoding = "UTF-8")
#     
#     ## TRY TO PARSE JSON RESPONSE
#     try(expr = {
#         resp <- jsonlite::fromJSON(resp_text)
#     }, silent = TRUE)
#     
#     
#     ## STATUS MESSAGE FORM HTTP HEADER <not currently implemented>
#     # post_response_status_message <- httr::http_status(http_response)$message
#     
#     return(list(post_prediction = resp,
#                 post_id = post_id))
# }
# 





