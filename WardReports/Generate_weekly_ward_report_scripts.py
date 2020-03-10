import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

#########################################################
#Pulling in data for email (to be transferred to a different script later)

client = civis.APIClient()

#actual ward table import to be used once testing is complete
'''
ward_email_data = civis.io.read_civis(database='City of Chicago',
                                      table = 'scratch.ward_office_info',
                                      use_pandas = True)
                                      '''

#Generate fake table that should be replaced with actual ward table later
wards = list(range(1,51))
emails = ['srao@civisanalytics.com' for i in range(50)]
ward_email_data = pd.DataFrame(list(zip(wards, emails)),
               columns =['WARD', 'Ward_Office_Email'])

#Number of weeks since the census started
def weeks_of_census():
    census_start = dt.date(2020, 3, 12)
    today_date = dt.date.today()
    delta = today_date - census_start
    num_days = delta.days
    weeks = math.floor(num_days/7)
    return weeks

#Pull ward aggregation and household data
query = """SELECT * FROM cic.ward_visualization_table;"""
ward_agg = civis.io.read_civis_sql(query,database='City of Chicago',use_pandas = True)
ward_agg.dropna(inplace=True)

#Calculate counted and uncounted households per ward
ward_agg['Counted Households'] = round(ward_agg['mail_return_rate_cen_2010'] * (ward_agg['tot_housing_units_acs_13_17']/100))
ward_agg['Uncounted Households'] = ward_agg['tot_housing_units_acs_13_17'] - ward_agg['Counted Households']
ward_agg['Percent Counted'] = round(ward_agg['Counted Households']*100/ward_agg['tot_housing_units_acs_13_17'],1)
ward_agg['Percent Uncounted'] = round(ward_agg['Uncounted Households']*100/ward_agg['tot_housing_units_acs_13_17'],1)

#Calculate City of Chicago uncounted stats
total_reported_perc = round(ward_agg['Counted Households'].sum()*100/ward_agg['tot_housing_units_acs_13_17'].sum(),1)
households_left = ward_agg['Uncounted Households'].sum()

best_performer = int(ward_agg[ward_agg['Percent Counted']==ward_agg['Percent Counted'].max()]['ward'].values[0])

#Create a function that returns a dictionary of all the household count stats per ward
def counted_per_ward(ward_number):
    counted = ward_agg[ward_agg['ward']==ward_number]['Counted Households'].values[0]
    uncounted = ward_agg[ward_agg['ward']==ward_number]['Uncounted Households'].values[0]
    per_counted = ward_agg[ward_agg['ward']==ward_number]['Percent Counted'].values[0]
    per_uncounted = ward_agg[ward_agg['ward']==ward_number]['Percent Uncounted'].values[0]
    counted_dict = {"Num_Counted": counted,
                   "Num_Uncounted": uncounted,
                   "Perc_Counted": per_counted,
                   "Perc_Uncounted": per_uncounted}
    return counted_dict

#Pull daily response rate data
query = """SELECT rates.gidtr, rates.date, rates.rate, viz.ward
            FROM cic.daily_response_rates_2010 as rates
            JOIN cic.visualization_table as viz
            ON viz.gidtr=rates.gidtr"""
drate_j_ward = civis.io.read_civis_sql(query,database='City of Chicago',use_pandas = True)
drate_j_ward.dropna(inplace=True)

drate_j_ward['date'] = pd.to_datetime(drate_j_ward['date'])

#real dates to be used later
#today = np.datetime64('today')
#last_week_end = np.datetime64('today') - np.timedelta64(7,'D')
#last_week_begin = last_week_end - np.timedelta64(7,'D')

#comment this out later to use real dates
today = np.datetime64('2010-04-27')
last_week_end = np.datetime64('2010-04-20')
last_week_begin = np.datetime64('2010-04-13')

#masks to select for weeks
this_week_mask = (drate_j_ward['date'] > last_week_end) & (drate_j_ward['date'] <= today)
last_week_mask = (drate_j_ward['date'] > last_week_begin) & (drate_j_ward['date'] <= last_week_end)

#subsetting data by week
this_week = drate_j_ward.loc[this_week_mask]
last_week = drate_j_ward.loc[last_week_mask]

#Calculate rates for the last two weeks of each ward
ward_weekly_rates = []
for i in range (1,51):
    ward = i
    this_week_rate = this_week.loc[(this_week['ward'] == ward)]['rate'].mean()
    last_week_rate = last_week.loc[(last_week['ward'] == ward)]['rate'].mean()
    ward_weekly_rates.append({'WARD' : ward,
                          "This Week Rate" : this_week_rate,
                         "Last Week Rate" : last_week_rate})
ward_weekly_rate_df = pd.DataFrame(ward_weekly_rates)

ward_weekly_rate_df['Rate_Change'] = ward_weekly_rate_df["This Week Rate"] - ward_weekly_rate_df["Last Week Rate"]

#Calculate most improved ward and the rate improvement
max_weekly_rate_change = ward_weekly_rate_df["Rate_Change"].max()
max_weekly_rate_change_percent = round(max_weekly_rate_change*100,1)
most_improved_ward = ward_weekly_rate_df[ward_weekly_rate_df["Rate_Change"] == max_weekly_rate_change]["WARD"].values[0]

##################################################################
#Here starts the actual email generation

#Function to create email_body (this is just markdown)
def create_email_body(ward_number):
    email_body = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal.png)


Dear Ward {ward_number},

Today is week {weeks_of_census()} of the Census Response Period. As of today, {int(counted_per_ward(ward_number)['Num_Counted']):,} households in your ward have responded to the 2020 Census. This means there are about **{int(counted_per_ward(ward_number)['Num_Uncounted']):,} households left to count**!

Here are some additional facts about how Chicago wards are doing:

* **Best performer** *: Ward {best_performer} has had {ward_agg['Percent Counted'].max()}% of all its households respond so far (Your Ward is at {counted_per_ward(ward_number)['Perc_Counted']}%)

* **Most improved**: Ward {most_improved_ward} had a {max_weekly_rate_change_percent}% increase in the number of households responding compared to last week (Your Ward is at {round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0]*100,2)}%).

Overall, {total_reported_perc}% of all Chicagoans have responded to the Census. There are about {int(households_left):,} households left to count in Chicago.

Remember, for every additional person counted in Chicago, the City receives approximately $1,400 to put towards parks, schools, and infrastructure!

*Performance is measured based on how well each ward is performing relative to performance in the 2010 Census
'''
"""
    return email_body


#Create function that defines the "source script" of the new script that get generated, inc ward email address
def create_source_script(ward_number, ward_email_data):
    source_str = f"""import os \n
import civis \n
from datetime import date \n

client = civis.APIClient()

client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Ward {ward_number} Report {dt.date.today().strftime("%m/%d/%Y")}',
        'success_email_body' : {create_email_body(ward_number)},
        'success_email_addresses' : ['{ward_email_data[ward_email_data['WARD']==ward_number]['Ward_Office_Email'].values[0]}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(ward_number):
    new_script = client.scripts.post_python3(name = 'Ward_'+str(ward_number) + '_script',
                                source = create_source_script(ward_number,ward_email_data))
    return new_script


#Loop that calls function that makes new script
for i in range(1,51):
    temp_job_id = create_new_email_script(i)['id']
    print(temp_job_id)
    run_job_report = client.scripts.post_python3_runs(temp_job_id)
    print(run_job_report)
