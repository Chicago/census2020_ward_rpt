

census_getter_cook <- function(keyfile = "config/census_api_key.yaml"){
    # browser()
    require(data.table)
    require(httr)
    censuskey <- yaml::read_yaml(keyfile)$census_api_key
    
    ## All census tracts in Cook County by components
    baseurl <- "https://api.census.gov/data/2020/dec/responserate?"
    parts <- list("get=GEO_ID,RESP_DATE,DRRALL,CRRALL,DRRINT,CRRINT",
                  "for=tract:*",
                  "in=state:17%20county:031",
                  "key=APIKEY")
    url <- paste0(baseurl, paste(parts, collapse = "&"))
    url <- gsub("APIKEY", censuskey, url)
    resp <- census_getter(url)
    return(resp)
}

## Notes and examples: 

if(FALSE){
    
    # rm(list=ls())
    source("functions/census_getter.R")
    source("functions/census_getter_cook.R")
    resp <- census_getter_cook()
    resp
    dir.create("data_daily_resp_cook")
    fname <- file.path("data_daily_resp_cook", sprintf("cook %s.csv", Sys.Date()))
    
    if(!file.exists(fname)){
        cat("writing file\n")
        fwrite(resp, fname)
    }
    ## Import column descriptions
    vars <- fread("data_daily_resp_cook/apivars.csv")
    vars[match(colnames(resp), name), list(name, label)]
    
    ############################################################################
    ## censusapi examples
    ## https://cran.r-project.org/web/packages/censusapi/vignettes/getting-started.html
    ############################################################################
    
    library(censusapi)
    # options(datatable.prettyprint.char=NULL)
    options(datatable.prettyprint.char=90L)
    Sys.setenv(CENSUS_KEY=yaml::read_yaml("config/census_api_key.yaml")$census_api_key)
    
    apis <- data.table(listCensusApis())
    api_vars <- listCensusMetadata(name = "2020/dec/responserate", type = "variables")
    fwrite(api_vars, "data_daily_resp_cook/apivars.csv")
    
}


