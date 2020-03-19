

# Census 2020 Report Development

Basic markdown report with public data for ward / CA reporting. Contents of report are focused on demographic data related to populations with expected low response rates, or a high LRS (Low Response Score) according to the Census Bureau. 


## Civis API key

For instuctions on how to set an API key please refer to Civis documentation: <br>
https://civisanalytics.github.io/civis-r/ <br>
https://civis.zendesk.com/hc/en-us/articles/216341583-Generating-an-API-Key

In `config/setkey.R` there is a simple script to set the API key for each session.  The script looks like this, except with an actual API key:
`Sys.setenv(CIVIS_API_KEY="<PUT YOUR API KEY HERE>")`


