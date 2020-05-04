#!/bin/bash


## use this command to run:
## nohup ./runapp.sh &


###############################################################################
## Save file
###############################################################################
nohup R -e "source('daily_response_rate_download.R')" &


##=============================================================================
## Run census script in crontab
##=============================================================================
## GLOBAL VARIABLES
# census_rpt_path=/app/GWL/census2020_ward_rpt/
# 
# 23 15 * * * cd $census_rpt_path && nohup ./daily_response_rate_download.sh &
 
 