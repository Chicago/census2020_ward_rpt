rm(list=ls())

library(data.table)
library(censusapi)
library(magrittr)
library(yaml)

source("functions/sourceDir.R")
sourceDir("functions")

##------------------------------------------------------------------------------
## GET / SET CENSUS KEY
##------------------------------------------------------------------------------

## You can register for a key here: https://api.census.gov/data/key_signup.html

censuskey <- yaml::read_yaml("config/census_api_key.yaml")$census_api_key

## Set the key as a system variable for use with the censusapi library
Sys.setenv(CENSUS_KEY=censuskey)
Sys.getenv("CENSUS_KEY")

##------------------------------------------------------------------------------
## SEE CENSUSAPI DOCUMENTATION FOR EXAMPLES:
## https://hrecht.github.io/censusapi/articles/example-masterlist.html#decennial-census-self-response-rates
## https://hrecht.github.io/censusapi/articles/
##------------------------------------------------------------------------------


##------------------------------------------------------------------------------
## 2010 POPULATIONS
##------------------------------------------------------------------------------

geos <- listCensusMetadata(name = "dec/sf1", 
                           vintage = 2010, 
                           type = "geographies", 
                           group = "P1")
str(geos,1)

## Open in Excel
# geneorama::wtf(geos[, 1:3])

## View variables
listCensusMetadata(name = "dec/sf1", 
                   vintage = 2010, 
                   type = "variables", 
                   group = "P1")
listCensusMetadata(name = "dec/sf1", 
                   vintage = 2010, 
                   type = "variables", 
                   group = "P2")

## 2010 Populations for all Places
population2010 <- getCensus(name = "dec/sf1",
                            vintage = 2010,
                            vars = c("NAME", "P001001", "H010001"),
                            region = "place:*") %>% 
    data.table() %>% 
    .[order(-H010001)]

# geneorama::wtf(population2010)
head(population2010)

##------------------------------------------------------------------------------
## PLANNING DATABASE FOR COOK
##------------------------------------------------------------------------------
pdb_meta <- data.table(listCensusMetadata(name = "pdb/blockgroup", 
                                          vintage = 2018, 
                                          type = "variables"))
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
# geneorama::wtf(pdb)
head(pdb)

##------------------------------------------------------------------------------
## LIST OF PLACES
##------------------------------------------------------------------------------
places_url <- "https://api.census.gov/data/2018/acs/acs1?get=B00001_001E,NAME&for=place:*"
places <- httr::GET(url = places_url) %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON() %>%
    data.table
## First row is actually header
places <- setnames(places[-1, ], 
                   unlist(places[1, ]))
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

place_responses <- getCensus(name = "dec/responserate",
                             vintage = 2020,
                             vars = c("NAME", "RESP_DATE", "CRRALL", "CRRINT"),
                             region = "place:*",
                             regionin = "state:*") %>% 
    data.table
place_responses

##------------------------------------------------------------------------------
## 2020 RESPONSE RATE FOR PLACES, MERGED WITH POPULATION AND PLACE DATA
##------------------------------------------------------------------------------
str(places)
place_responses_merged <- merge(place_responses, 
                                places,
                                key = c("state", "place"),
                                all.x = TRUE)
place_responses_merged <- merge(place_responses_merged, 
                                population2010,
                                key = c("state", "place"),
                                all.x = TRUE)
place_responses_merged

## Open in Excel (not run / run manually)
## Also, possible to use fwrite

# geneorama::wtf(place_responses_merged)


##------------------------------------------------------------------------------
## CENSUS EXAMPLES USING "census_getter" FUNCTION, AND DEVELOPMENT
##------------------------------------------------------------------------------

if(FALSE){
    
    ## Needed, but should be already loaded:
    source("functions/sourceDir.R")
    sourceDir("functions")
    censuskey <- yaml::read_yaml("config/census_api_key.yaml")$census_api_key
    
    ## DEFINE BASE URL    
    base_resp_url <- "https://api.census.gov/data/2020/dec/responserate?"
    
    ## TRACT LEVEL DATA FOR COOK COUNTY
    tract_resp <- list("get=GEO_ID,DRRALL,DRRINT,CRRALL,CRRINT",
                       # "RESP_DATE:2020-03-22", ## NOTE: UNABLE TO SPECIFY PAST DATES
                       "for=tract:*",
                       "in=state:17%20county:031",
                       "key=APIKEY") %>% 
        paste(., collapse = "&") %>% 
        gsub("APIKEY", censuskey, .) %>% 
        paste0(base_resp_url, .) %>% 
        census_getter
    tract_resp
    
    ## COUNTY LEVEL FOR COOK COUNTY
    county_resp <- list("get=GEO_ID,DRRALL,DRRINT,CRRALL,CRRINT",
                       "for=county:031",
                       "in=state:17",
                       "key=APIKEY") %>% 
        paste(., collapse = "&") %>% 
        gsub("APIKEY", censuskey, .) %>% 
        paste0(base_resp_url, .) %>% 
        census_getter
    county_resp
    
    ## STATE LEVEL RESPONSE RATES
    state_response_rates <- list("get=GEO_ID,DRRALL,DRRINT,CRRALL,CRRINT",
                                 "for=state:*",
                                 "key=APIKEY") %>% 
        paste(., collapse = "&") %>% 
        gsub("APIKEY", censuskey, .) %>% 
        paste0(base_resp_url, .) %>% 
        census_getter
    
    ## Individual steps to get state level rates
    state_resp_url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=state:*"
    state_resp <- state_resp_url %>%
        httr::GET(url = .) %>%
        httr::content(., as = "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(.) %>%
        data.table
    state_resp <- setnames(state_resp[-1, ],
                           unlist(state_resp[1, ]))
}

