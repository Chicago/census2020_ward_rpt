
# rm(list=ls())

## Run once to install geneorama:
# install.packages("devtools")
# devtools::install_github("geneorama/geneorama")

library(geneorama)

## Set the working directory to the project folder
set_project_dir("census2020_ward_rpt") ## geneorama

## LOAD LATEST DATA CACHE
load(max(list.files("WardReport_v2/cache", full.names = T)))

## LOAD LIBRARIES (geneorama function)
loadinstall_libraries(c("shiny","leaflet","RColorBrewer","colorspace","rgdal",
                        "rgeos","sp","data.table","plotly","sf","reactable",
                        "tmap","flexdashboard","yaml","htmltools",
                        "bit64","shinyjs"))

## LOAD FUNCTIONS (geneorama function)
sourceDir("functions")

##------------------------------------------------------------------------------
## WARD TO TRACT CROSSWALK
##------------------------------------------------------------------------------
ward_crosswalk <- fread("data_census_planning/crosswalk_replica_based.csv")
ward_crosswalk[ , tract := substr(TRACT, 6, 11)]

##------------------------------------------------------------------------------
## ADJUST CURRENT RESPONSE DATA TABLE
##------------------------------------------------------------------------------
resp_current$state <- NULL
resp_current$county <- NULL
## MERGE IN CIVIS DATA
resp_current <- merge(x = resp_current, y = civis_pdb,
                      by.x = "TRACT", by.y = "tract",
                      all.x = TRUE)
## MERGE IN HTC DATA
htc[ , tract_2020 := substr(TRACT_2020, 6, 11)]
resp_current <- merge(x = resp_current,
                      y = htc[!is.na(TRACT_2020), MailReturnRateCen2010:tract_2020],
                      by.x = "TRACT", by.y = "tract_2020", all.x = TRUE)
resp_current <- resp_current[!is.na(TRACT)]

##------------------------------------------------------------------------------
## Map color definitions
##------------------------------------------------------------------------------
# colorspace::choose_color()
# colorspace::choose_palette()
# colorspace::hcl_wizard()
cur_pal <- c("#754C17", "#B96B34", "#F29946", "#E0C245", # "#99DFF1",
             "#3BB8E2", "#7999B7", "#A18EB9","#694D87", "#3D2E4E")



# Define server logic required to draw a histogram
server <- function(input, output) {
  
  ## Create the current ward response table
  resp_cur_ward <- reactive({
    cur_ward <- input$cur_ward
    ## MERGE IN CROSSWALK
    resp_cur_ward <- merge(x = ward_crosswalk[ward == cur_ward,
                                              list(TRACT = tract,
                                                   ward, 
                                                   households_ward = households,
                                                   households_tract = tract_total,
                                                   allocation)], 
                           y = resp_current, 
                           by = "TRACT")
    resp_cur_ward[i = TRUE, 
                  LABEL := htmltools::HTML(
                    paste(paste0("Tract: ", TRACT),
                          paste0("As of ", RESP_DATE),
                          paste0("Total response rate is ", CRRALL, "%"),
                          paste0("Total internet response rate is ", CRRINT, "%"),
                          paste0("Households in tract: ",
                                 prettyNum(TotHH, big.mark=",")),
                          paste0("Households in ward: ",
                                 prettyNum(round(TotHH*households_ward/households_tract), 
                                           big.mark=",")),
                          paste0("Response rate 2010 (mail): ", mail_return_rate_cen_2010, "%"),
                          paste0("Predicted 2020 response rate:", 100-low_response_score, "%"),
                          paste0("Total population 2010:", tot_population_cen_2010),
                          paste0("Black population 2010:", nh_blk_alone_acs_13_17),
                          paste0("Hisp. population 2010:", hispanic_acs_13_17),
                          paste0("Limited English Proficiency (LEP):", eng_vw_acs_13_17),
                          paste0("Single Parents:", HH_SingleParent),
                          sep = "<br>")),
                  by = TRACT]
    ## Tract map of just this ward
    ## put data in same order as map
    shp_ward_tract <- shp_tracts_2020[shp_tracts_2020@data$TRACT %in% resp_cur_ward$TRACT, ]
    resp_cur_ward <- resp_cur_ward[match(shp_ward_tract@data$TRACT, resp_cur_ward$TRACT)]

    return(resp_cur_ward)
  })
  ## Shape file of just current ward
  shp_ward <- reactive({
    cur_ward <- input$cur_ward
    shp_ward <- shp_wards[shp_wards$ward == cur_ward, ]
    return(shp_ward)
  })
  civis_ward_table <- civis_ward_table[match(shp_wards$ward, civis_ward_table$ward)]
  civis_ward_table[ , LABEL := htmltools::HTML(hover_text), ward]
  
  
  ## put data in same order as map
  resp_current <- resp_current[match(shp_tracts_2020$TRACT, TRACT)]
  
  
  
  ## City wide response
  city_target_resp <- 75
  city_cur_resp <- civis_ward_table[
    i = TRUE,
    j = sum(tot_occp_units_acs_13_17 * current_response_rate) / sum(tot_occp_units_acs_13_17)]
  city_target_resp_civis <- civis_ward_table[
    i = TRUE,
    j = sum(tot_occp_units_acs_13_17 * civis_2020_target) / sum(tot_occp_units_acs_13_17)]
  city_cur_resp <- round(city_cur_resp, 1)
  
  ## Ward specific respopnse numbers
  ward_target_resp <- civis_ward_table[cur_ward, adjusted_civis_2020_target]
  ward_cur_resp <- civis_ward_table[cur_ward, current_response_rate]
  ward_target_resp_civis <- civis_ward_table[cur_ward, civis_2020_target]
  ward_ranking_adj <- civis_ward_table[ , list(ward,
                                               rank = rank(current_response_rate/civis_2020_target))][
                                                 ward == cur_ward, rank]
  
  ## Household totals for value boxes
  ward_hh_tot <- resp_cur_ward[ , sum(households_ward)]
  ward_hh_resp_daily <- resp_cur_ward[ , round(sum(households_ward * DRRALL/100))]
  ward_hh_resp_total <- resp_cur_ward[ , round(sum(households_ward * CRRALL/100))]
  
  
}


output$distPlot <- renderPlot({
  # generate bins based on input$bins from ui.R
  x    <- faithful[, 2] 
  bins <- seq(min(x), max(x), length.out = input$bins + 1)
  
  # draw the histogram with the specified number of bins
  hist(x, breaks = bins, col = 'darkgray', border = 'white')
})
}


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Old Faithful Geyser Data"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins",
                  "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

# Run the application 
shinyApp(ui = ui, server = server)

