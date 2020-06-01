

##==============================================================================
## INITIALIZE
##==============================================================================

rm(list=ls())

library(geneorama) ## Not actually needed
library(data.table)
library(openxlsx)
library("rgeos")
library("leaflet")
library("colorspace")
library("sp")
# library("spdep")
library("rgdal")
# library("RColorBrewer")
# library("ggplot2")
# library("bit64")
geneorama::loadinstall_libraries("corrplot")


sourceDir("functions/")


##==============================================================================
## DATA
##==============================================================================

##------------------------------------------------------------------------------
## Shape files
##------------------------------------------------------------------------------

shp_tracts_2020 <- readOGR("data_maps/tracts_2020_stuartlynn_Chicago.geojson", stringsAsFactors = FALSE)
shp_tracts_prev <- readOGR("data_maps/tracts_2019_chicago.geojson", stringsAsFactors = FALSE)

##------------------------------------------------------------------------------
## Locally collected responses for 2020
##------------------------------------------------------------------------------

resp_files <- list.files(path = "data_daily_resp_cook/", pattern = "^cook.+csv$", full.names = T)
resp <- rbindlist(lapply(resp_files, fread))
resp[ , tract := NULL]
resp[ , GEOID := substr(GEO_ID, 10, 20)]
resp[ , TRACT := substr(GEO_ID, 15, 20)]

## Get the current response and match the current response to the 2020 tract map
resp_current <- resp[RESP_DATE == max(RESP_DATE)]
resp_current <- resp_current[match(shp_tracts_2020$TRACT, TRACT)]
rm(resp, resp_files)

## Checking match between API and shape files
table(resp_current$TRACT %in% shp_tracts_2020$TRACT)
table(shp_tracts_2020$TRACT %in% resp_current$TRACT)
table(shp_tracts_prev$TRACTCE %in% resp_current$TRACT)

##------------------------------------------------------------------------------
## Crosswalk based on replica data
##------------------------------------------------------------------------------

to2020 <- fread("data_census_planning/crosswalk_to_2020.csv")
to2020[ , TRACT_2020 := as.character(TRACT_2020)]
to2020[ , TRACT_prev := as.character(TRACT_prev)]
to2020 <- to2020[ , list(TRACT_2020=TRACT_2020[which.max(allocation)]), TRACT_prev]

##------------------------------------------------------------------------------
## Demographic variables
##------------------------------------------------------------------------------
htc_tot <- openxlsx::read.xlsx("data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx",
                               sheet = 2, startRow = 6)
htc_tot <- data.table(htc_tot)
colnames(htc_tot)

htc_pct <- openxlsx::read.xlsx("data_census_planning/pdb2017tract_2010MRR_2018ACS_IL.xlsx",
                               sheet = 3, startRow = 6)
htc_pct <- as.data.table(htc_pct)
htc_pct[LowResponseScore == 99999, LowResponseScore := NA]
htc_pct[MailReturnRateCen2010 == 99999, MailReturnRateCen2010 := NA]

htc_pct <- merge(htc_pct,
                 htc_tot[ , list(GEOIDtxt, TotPop, TotHH, TotPopinHHs)],
                 by = "GEOIDtxt",
                 all.x = TRUE)

htc_pct[ , GEOID_2020 := to2020[match(GEOIDtxt, TRACT_prev), TRACT_2020]]
htc_pct[ , TRACT_2020 := substr(GEOID_2020, 6, 11)]
htc_pct[ , TRACT_PREV := substr(GEOIDtxt, 6, 11)]

htc_pct <- htc_pct[match(shp_tracts_2020$TRACT, TRACT_2020)]
sum(htc_pct$TotPop, na.rm=T)

table(na.omit(htc_pct$TRACT_2020) %in% na.omit(resp_current$TRACT))
table(na.omit(htc_pct$TRACT_2020) %in% resp_current$TRACT)

# clipper(htc_pct$TRACT_2020)
# clipper(htc_pct$TotPop)
# clipper(resp_current$CRRALL)
# clipper(shp_tracts_2020$TRACT)

# dput(colnames(htc_pct))


## Construct dat based on response data
# dat <- resp_current[ , list(GEOID, TRACT, RESP_DATE, CRRALL)]
# colnames(htc_pct)
# NAsummary(dat)
# NAsummary(htc_pct)


## Join demographic data to response data
## based on the correlation plot below I iteratively removed variables
dat <- merge(
  x = resp_current[!is.na(GEOID) , list(GEOID, TRACT, RESP_DATE, CRRALL)],
  y = htc_pct[i = TRUE,
              j = list(TRACT = TRACT_2020,
                       # GEOIDtxt, StateFIPS, StateAbb, StateName, CountyFIPS, 
                       # CountyName, TractFIPS, MailReturnRateCen2010, LowResponseScore, 
                       # PctTotPop, 
                       PctTotUnder5_TotPopDenom, 
                       # PctHispanic_TotPopDenom, ## represented by households
                       PctBlackAloneOrCombo_TotPopDenom, 
                       # PctAsianAloneOrCombo_TotPopDenom, 
                       PctAmerIndAloneorCombo_TotPopDenom, 
                       PctNatHawAloneOrCombo_TotPopDenom, 
                       # PctTotHH, PctTotPopinHHs_TotPopDenom, PctGroupQuarter_TotPopDenom, 
                       PctLEPHHs_TotHHDenom, 
                       PctLEPspanHHs_TotHHDenom, PctLEPindoeurHHs_TotHHDenom, 
                       PctLEPapacHHs_TotHHDenom, PctLEPotherHHs_TotHHDenom, 
                       PctTotPopBornOutUS_TotPopDenom, 
                       PctFB2010Plus_FBDenom, PctFB2000Plus_FBDenom, 
                       # PctOwner_TOTAL_HUDenom, 
                       # PctRenter_TOTAL_HUDenom, 
                       PctHH_SingleParent_TotHHDenom, 
                       PctHH_Crowded_TotHHDenom, PctHH_Owner_Crowded_CrowdHHDenom, 
                       PctHH_Renter_Crowded_CrowdHHDenom, 
                       # PctPoverty_TOTAL, 
                       # PctPoverty_Less100_PovDenom, 
                       PctPoverty_Less200_PovDenom, 
                       # PctHousingUnits_TOTAL, 
                       PctUnits_2Plus_HUDenom, PctUnits_10Plus_HUDenom, 
                       # PctNoInternet_TotHHDenom, 
                       PctInternet_NoSub_TotHHDenom, 
                       PctInternet_TotHHDenom, PctDialUpOnly_TotHHDenom, 
                       PctBroadband_Any_TotHHDenom, 
                       # PctBroadband_CableFiberOpticDSL_TotHHDenom, 
                       PctBroadband_CableFiberOpticDSLOnly_TotHHDenom,
                       PctCellular_TotHHDenom, 
                       PctCellularOnly_TotHHDenom, PctSatellite_TotHHDenom, PctSatelliteOnly_TotHHDenom, 
                       PctOtherOnly_TotHHDenom, PctHHer15to34_TotHHDenom, PctHHer35to54_TotHHDenom, 
                       PctHHer55to64_TotHHDenom, 
                       # PctHHer65plus_TotHHDenom, 
                       PctMoved2015later_TotHHDenom, PctMove10to14_TotHHDenom, 
                       PctMoved00to09_TotHHDenom, PctMoved90to99_TotHHDenom, 
                       PctMoved1989earlier_TotHHDenom,
                       PctIntFirstEng_TotHUDenom,
                       PctIntFirstBiling_TotHUDenom, PctIntChoiceEng_TotHUDenom,
                       PctIntChoiceBiling_TotHUDenom 
                       # PctMailTypeNotKnown_TotHUDenom,
                       # PctUpdateEnumerate_TotHUDenom, PctRemoteAlaska_TotHUDenom, 
                       # PctUpdateLeave_TotHUDenom, 
                       # TotPop, TotHH, TotPopinHHs, GEOID_2020, TRACT_2020, TRACT_PREV)
              )],
  by = "TRACT")
dat
NAsummary(dat)
str(dat)
# wtf(dat)


dat[ , CRRALL := CRRALL/100] 

##------------------------------------------------------------------------------
## xmat for model
##------------------------------------------------------------------------------

## Get numeric values and calc correlation
names(which(sapply(dat, class)!="numeric"))
xmat <- dat[ , names(which(sapply(dat, class)=="numeric")), with = FALSE]

# setnames(xmat, gsub("_tothhdenom", "", colnames(xmat)))
# setnames(xmat, gsub("_totpopdenom", "", colnames(xmat)))
# setnames(xmat, gsub("broadband", "BB", colnames(xmat)))
# setnames(xmat, gsub("^pct", "", colnames(xmat)))
xmat

temp <- copy(xmat)
setnames(temp, paste0("V", 1:ncol(temp)))
corrplot(corr = cor(temp), 
         col = colorRampPalette(c("#7F0000", "red", "#FF7F00", "yellow", "#7FFF7F", 
                                  "cyan", "#007FFF", "blue", "#00007F"))(100))
rm(temp)

xmatcor <- cor(xmat)
xmatcor[!lower.tri(xmatcor)] <- 0
xmatcor <- abs(xmatcor)
xmatcor <- xmatcor[apply(xmatcor, 1, function(x) any(x>.8)), ]
xmatcor <- xmatcor[ , apply(xmatcor, 2, function(x) any(x>.8))]
# clipper(data.frame(rownames(xmatcor), xmatcor))
xmatcor
plot(xmat[ , rownames(xmatcor), with=F])


## Correlated with Response Rate
names(tail(sort(cor(xmat)[,1]), 6))
plot(CRRALL ~ PctInternet_TotHHDenom, data=dat)
plot(CRRALL ~ PctUnits_10Plus_HUDenom, data=dat)
plot(CRRALL ~ PctCellular_TotHHDenom, data=dat)
plot(CRRALL ~ PctBroadband_CableFiberOpticDSLOnly_TotHHDenom, data=dat)


## SET UP DATA
set.seed(8)
ii <- sort(sample(1:nrow(dat), size = nrow(dat)*.75))

xmatTest <- xmat[-ii, -"CRRALL"]
xmatTrain <- xmat[ii, -"CRRALL"]
yTrain <- xmat[ii, CRRALL]
yTest <- xmat[-ii, CRRALL]


## GLMNET TEST
geneorama::loadinstall_libraries("glmnet")
glm1 <- cv.glmnet(x = as.matrix(xmatTrain), y = yTrain)
yhat <- glmnet::predict.glmnet(object = glm1$glmnet.fit,
                               newx = as.matrix(xmat[,-"CRRALL"]),
                               s = glm1$lambda.min,
                               type = "response")[,1]
yhatTest <- yhat[-ii]
yhatTrain <- yhat[ii]
rm(yhat)

plot(yhatTrain ~ yTrain)
plot(yhatTest ~ yTest)
cor(yTest, yhatTest)^2
cor(yTrain, yhatTrain)^2

glm1
# glm1$glmnet.fit

glmcoef <- data.table(var = rownames(coef(glm1)),
                      coef = as.matrix(coef(glm1))[,1])
glmcoef[ , i := .I]
glmcoef
# clipper(glmcoef)
# plot(lowresponsescore~average_household_income, dat)
# plot(lowresponsescore~pcttotunder5_totpopdenom, dat)





plot(dat$CRRALL ~ dat$PctHH_SingleParent_TotHHDenom)

plot(dat$CRRALL ~ dat$PctLEPspanHHs_TotHHDenom)
plot(dat$CRRALL ~ dat$PctPoverty_Less200_PovDenom)
plot(dat$CRRALL ~ dat$PctCellularOnly_TotHHDenom)
plot(dat$CRRALL ~ dat$PctUnits_2Plus_HUDenom)
plot(dat$CRRALL ~ dat$PctInternet_NoSub_TotHHDenom)
plot(dat$CRRALL ~ dat$PctHH_SingleParent_TotHHDenom)
plot(dat$CRRALL ~ dat$PctBroadband_CableFiberOpticDSLOnly_TotHHDenom)
plot(dat$CRRALL ~ dat$PctUnits_10Plus_HUDenom)
plot(dat$CRRALL ~ dat$PctInternet_TotHHDenom)

datplot <- copy(dat)
datplot$hisp_lep <- dat$PctLEPspanHHs_TotHHDenom
datplot$response_rate_2020 <- dat$CRRALL

library(ggplot2)
ggplot(datplot) + 
  aes(x=PctLEPspanHHs_TotHHDenom, y=response_rate_2020, 
                  colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Spanish Speaking Households",
          subtitle = "as of 4/5/2020")
ggplot(datplot) + 
  aes(x=PctPoverty_Less200_PovDenom, y=response_rate_2020, 
      colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Poverty",
          subtitle = "as of 4/5/2020")
ggplot(datplot) + 
  aes(x=PctInternet_TotHHDenom, y=response_rate_2020, 
      colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Internet",
          subtitle = "as of 4/5/2020")
ggplot(datplot) + 
  aes(x=PctUnits_2Plus_HUDenom, y=response_rate_2020, 
      colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Buildings 2+ units",
          subtitle = "as of 4/5/2020")

##------------------------------------------------------------------------------
## Example of using lowess
##------------------------------------------------------------------------------
lowess_model <- datplot[ , lowess(response_rate_2020 ~ PctLEPspanHHs_TotHHDenom,
                                   f = .1)]
ggplot(datplot) + 
  aes(x=PctLEPspanHHs_TotHHDenom, y=response_rate_2020, 
      colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Buildings 2+ units",
          subtitle = "as of 4/5/2020")+
  geom_point(mapping = aes(x,y), data = lowess_model, col="red") +
  geom_line(mapping = aes(x,y), data = lowess_model, col="red")


##------------------------------------------------------------------------------
## Example of using loess
##------------------------------------------------------------------------------
loess_model <- datplot[ , loess(response_rate_2020 ~ PctLEPspanHHs_TotHHDenom,
                                 span = .75, degree = 2)]
loess_model
pred <- data.frame(PctLEPspanHHs_TotHHDenom=seq(0, 1, .01))
pred$fit <- predict(loess_model, pred, se = !TRUE)
setnames(pred, c("x","y"))
plot(pred)

ggplot(datplot) + 
  aes(x=PctLEPspanHHs_TotHHDenom, y=response_rate_2020, 
      colour=hisp_lep) +  
  geom_point() + geom_smooth() + expand_limits(y = c(0, 1)) +
  ggtitle(label = "Relationship of 2020 Response and Buildings 2+ units",
          subtitle = "as of 4/5/2020")+
  geom_point(mapping = aes(x,y), data = pred, col="red") +
  geom_line(mapping = aes(x,y), data = pred, col="red")


# influencers <- data.table(gbm::summary.gbm(object = gbm1, n.trees = best.iter, plotit = F))
# influencers[ , var:=as.character(var)]
# str(influencers)
# combo <- merge(influencers, glmcoef, "var", all=T)
# # clipper(combo)
# 
# 
# plot(lowresponsescore~pctowner_total_hudenom, dat)
# plot(pctowner_total_hudenom~pcthh_singleparent_tothhdenom, dat)
# 
# library(ggplot2)
# pl
# ggplot
# 
# 
# ## GLMNET TOP INFLUENCERS
# datglm2 <- xmat[,list(pctpoverty_less200_povdenom,
#                       pcthh_singleparent_tothhdenom,
#                       pctowner_total_hudenom,
#                       average_household_income,
#                       pctpoverty_less100_povdenom,
#                       pcthher65plus_tothhdenom,
#                       pctrenter_total_hudenom,
#                       pctbroadband_cablefiberopticdsl_tothhdenom,
#                       pctasianaloneorcombo_totpopdenom,## TOP
#                       pctmoved00to09_tothhdenom,
#                       pcthispanic_totpopdenom,
#                       pctgroupquarter_totpopdenom)]
# glm2 <- cv.glmnet(x = as.matrix(datglm2), y = y)
# yhat <- glmnet::predict.glmnet(object = glm2$glmnet.fit,
#                                newx = as.matrix(datglm2),
#                                s = glm2$lambda.min,
#                                type = "response")[,1]
# plot(yhat~y)
# cor(y, yhat)^2
# coef(glm2)
# yhatTest <- glmnet::predict.glmnet(object = glm2$glmnet.fit,
#                                    newx = as.matrix(xmatTest[,colnames(datglm2),with=F]),
#                                    s = glm2$lambda.min,
#                                    type = "response")[,1]
# plot(yhatTest~yTest)
# cor(yTest, yhatTest)^2
# glm2
# # glm2$glmnet.fit
# 
# glmcoef <- data.table(var = rownames(coef(glm2)),
#                       coef = as.matrix(coef(glm2))[,1])
# glmcoef[ , i := .I]
# glmcoef
# # clipper(glmcoef)
# plot(lowresponsescore~average_household_income, dat)
# plot(lowresponsescore~pcttotunder5_totpopdenom, dat)
# 
# 
# influencers <- data.table(gbm::summary.gbm(object = gbm1, n.trees = best.iter, plotit = F))
# influencers[ , var:=as.character(var)]
# str(influencers)
# combo <- merge(influencers, glmcoef, "var", all=T)
# # clipper(combo)
# 
# 
# 
# plot(lowresponsescore~pcthh_singleparent_tothhdenom, dat)
# plot(lowresponsescore~pctowner_total_hudenom, dat)
# plot(pctowner_total_hudenom~pcthh_singleparent_tothhdenom, dat)
# 

