

census_getter <- function(url){
    # browser()
    require(data.table)
    require(httr)
    
    http_response <- httr::GET(url = url)
    resp_text <- httr::content(http_response, as = "text", encoding = "UTF-8")
    resp <- jsonlite::fromJSON(resp_text)
    resp <- data.frame(resp, stringsAsFactors = F)
    resp_dt <- data.table(resp[-1, ])
    setnames(resp_dt, unlist(resp[1, ]))
    tf <- tempfile()
    fwrite(resp_dt, tf)
    resp_dt <- fread(tf)
    file.remove(tf)
    rm(tf)
    return(resp_dt)
}

## Notes and examples: 

if(FALSE){
    
    # rm(list=ls())
    
    censuskey <- yaml::read_yaml("config/census_api_key.yaml")$census_api_key
    
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
    
    
    ## Example of all 50 states
    census_getter("https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=state:*")
    
    ## Cook County by itself
    url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=county:031&in=state:17"
    census_getter(url)
    
    ## All census tracts in Cook County
    url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=tract:*&in=state:17%20county:031&key=60179a2964868d80e37ab0d49e88e654dedf0bc5"
    census_getter(url)
    
    ## All census tracts in Cook County with yaml key
    url <- "https://api.census.gov/data/2020/dec/responserate?get=DRRALL,CRRINT,RESP_DATE,CRRALL,GEO_ID,DRRINT&for=tract:*&in=state:17%20county:031&key=APIKEY"
    url <- gsub("APIKEY", censuskey, url)
    census_getter(url)

    ## All census tracts in Cook County by components
    baseurl <- "https://api.census.gov/data/2020/dec/responserate?"
    parts <- list("get=GEO_ID,RESP_DATE,DRRALL,CRRALL,DRRINT,CRRINT",
                  "for=tract:*",
                  "in=state:17%20county:031",
                  "key=APIKEY")
    url <- paste0(baseurl, paste(parts, collapse = "&"))
    url <- gsub("APIKEY", censuskey, url)
    census_getter(url)
    
    ## All census tracts in Cook County by components
    ## All dates
    baseurl <- "https://api.census.gov/data/2020/dec/responserate?"
    parts <- list("get=DRRALL,CRRINT,CRRALL,GEO_ID,DRRINT",
                  "RESP_DATE:2020-03-22",
                  "for=tract:*",
                  "in=state:17%20county:031",
                  "key=APIKEY")
    url <- paste0(baseurl, paste(parts, collapse = "&"))
    url <- gsub("APIKEY", censuskey, url)
    census_getter(url)
    
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
    
    
    
}


