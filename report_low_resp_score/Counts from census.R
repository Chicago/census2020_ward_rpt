
# COMPARE RATES
# 

## Initially I was worried because the 2010 response rate didn't match 
## return_count / total pop
## but the calc should be 
## return_count / forms mailed
## Then I found another data source that seemed off, but that was because it's 
## 2000 tracts:
# https://www.census.gov/data/datasets/2010/dec/2010-participation-rates.html




##==============================================================================
## INITIALIZE
##==============================================================================

rm(list=ls())

library(geneorama) ## Not actually needed
library(data.table)
library("rgeos")
library("leaflet")
library("colorspace")
library("sp")
# library("spdep")
library("rgdal")
library("RColorBrewer")
# library("ggplot2")
# library("bit64")


sourceDir("functions/")

##==============================================================================
## IMPORT DATA
##==============================================================================

## Import calculated databased on county wide data
datMailRates <- as.data.table(readOGR("data_maps/tracts.geojson")@data)
htc <- openxlsx::read.xlsx("data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx",
                           sheet = 2, startRow = 6)
htc <- as.data.table(htc)
ii <- match(datMailRates$GEOID, htc$GEOIDtxt)
htc <- htc[ii]
htc

plot(MailReturnRateCen2010 ~ LowResponseScore, htc)
htc[LowResponseScore == 99999, LowResponseScore := NA]
htc[MailReturnRateCen2010 == 99999, MailReturnRateCen2010 := NA]
plot(MailReturnRateCen2010 ~ LowResponseScore, htc)

## Import new rates

rates <- fread("data_census_planning/Counts from census.txt",
               sep="|", nrows = -10, header = F,
               select = c(1,3,5,7,9), 
               col.names = c("tract", "name", "type", "r1", "r2"),
               colClasses = c("character"))
rates[ , r1:=as.numeric(r1)]
rates[ , r2:=as.numeric(r2)]
NAsummary(rates)

chirates <- rates[match(htc$geoidtxt, tract)]
chirates[, which(is.na(tract))[1]]
htc$geoidtxt[2]

plot(htc$mailreturnratecen2010~chirates[, ifelse(r1==999,NA,r1)])
plot(htc$mailreturnratecen2010~chirates[, ifelse(r2==999,NA,r2)])
plot(htc$lowresponsescore~chirates[, ifelse(r1==999,NA,r1)])
plot(htc$lowresponsescore~chirates[, ifelse(r2==999,NA,r2)])

htc <- htc[match(datMailRates$GEOID, htc$geoidtxt)]
plot(datMailRates$mail_return_rate ~ htc$mailreturnratecen2010)

datMailRates[ , hist(mail_return_rate/100-(mail_return_count/total_population))]
datMailRates[ , plot(mail_return_rate/100,(mail_return_count/total_population))]
datMailRates[ , plot(mail_return_rate/100,(mail_return_count/total_forms_mailed))]
datMailRates[ , hist(mail_return_rate/100)]


