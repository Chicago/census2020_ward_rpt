


library(yaml)
source("functions/census_getter.R")
source("functions/census_getter_cook.R")
resp <- census_getter_cook()
resp
fname <- file.path("data_daily_resp_cook", sprintf("cook %s.csv", Sys.Date()))

if(!file.exists(fname)){
    cat("writing file ", fname, "\n")
    fwrite(resp, fname)
}




