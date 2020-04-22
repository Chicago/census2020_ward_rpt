

# Census 2020 Ward Report

The ward reports from this project are published at https://www.chicago.gov/city/en/sites/census2020/home/ward-reports.html

These reports are based on demographic data from the US Census Bureau, open data from https://data.cityofchicago.org/, and projections provided by [Civis Analytics](https://www.civisanalytics.com/)

The reports provide current Census response rates combined with demographic data at a ward level, so that Aldermanic offices can better understand performance within their wards. 

The reports are rendered on a weekly basis as static, stand alone html files, but this project could be easily modified to run as an application on a Shiny Server. 

## Technical Details

The current final reports are located in `./WardReport_v2`, and the actual report is `WardReport_v2/WardReport.Rmd`. If you are curious to see how the report works, or to adapt it to your own needs, this is a good place to start. By default this will open the lasest cached file in the project, and the current ward number from `WardReport_v2\cur_ward.yaml`. 

The production process to generate the reports is as follows:

First create a new cache run `WardReport_v2/10_refresh_cache.R`. This is necesary to speed up the render process. The cache includes data for allwards, but the static dashboard is rendered for just one subset.

Second, to render the reports for each ward run `WardReport_v2/20_render_reports.R`. This chagnes the current ward number in `WardReport_v2\cur_ward.yaml` and renders the report based on the actual report markdown file `WardReport_v2/WardReport.Rmd`, and saves the results in an output folder.

As a side note, the report could easily be made into a modular application in Shiny's reactive framework. 

