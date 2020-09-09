
##
## Shortcut function to specify our database, and automatically use data.table
##

read_civis_query <- function(q, db_name = "City of Chicago"){
    sql_q <- sql(q)
    df <- read_civis(sql_q, database=db_name, stringsAsFactors = FALSE)
    dt <- data.table(df)
    return(dt)
}
