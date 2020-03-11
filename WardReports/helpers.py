import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

#Number of weeks since the census started
def weeks_of_census():
    census_start = dt.date(2020, 3, 12)
    today_date = dt.date.today()
    delta = today_date - census_start
    num_days = delta.days
    weeks = math.ceil(num_days/7)
    return weeks

def get_weekly_rate_df():
    query = """SELECT rates.gidtr, rates.date, rates.rate, viz.ward
                FROM cic.daily_response_rates_2010 as rates
                JOIN cic.visualization_table as viz
                ON viz.gidtr=rates.gidtr"""
    drate_j_ward = civis.io.read_civis_sql(query, database = 'City of Chicago', use_pandas = True)
    drate_j_ward.dropna(inplace = True)

    drate_j_ward['date'] = pd.to_datetime(drate_j_ward['date'])
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

    return ward_weekly_rate_df

#Create a function that returns a dictionary of all the household count stats per ward
def counted_per_ward(ward_agg, ward_number):
    subset = ward_agg[ward_agg['ward']==ward_number]
    counted = subset['Counted Households'].values[0]
    uncounted = subset['Uncounted Households'].values[0]
    per_counted = subset['Percent Counted'].values[0]
    per_uncounted = subset['Percent Uncounted'].values[0]
    counted_dict = {"Num_Counted": counted,
                   "Num_Uncounted": uncounted,
                   "Perc_Counted": per_counted,
                   "Perc_Uncounted": per_uncounted}
    return counted_dict

#Function to create email_body in markdown
def create_email_body(ward_number, ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user):

    total_reported_perc = ward_stats["total_reported_perc"]
    households_left = ward_stats["households_left"]
    best_performer = ward_stats["best_performer"]
    most_improved_ward = ward_stats["most_improved_ward"]
    max_weekly_rate_change_percent = ward_stats["max_change_percent"]

    ward_email_rate = round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0]*100,2)

    email_body1 = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal_mobile_friendly.png)


Dear Ward {ward_number},

Today is week {weeks_of_census()} of the Census Response Period. As of today, {int(counted_per_ward(ward_agg, ward_number)['Num_Counted']):,} households in your ward have responded to the 2020 Census. This means there are about **{int(counted_per_ward(ward_agg, ward_number)['Num_Uncounted']):,} households left to count**!

Here are some additional facts about how Chicago wards are doing:

* **Best performer** *: Ward {best_performer} is at {ward_agg['Percent Counted'].max()}% of its target 2020 response rate (Your Ward is at {counted_per_ward(ward_agg, ward_number)['Perc_Counted']}%)

* **Most improved**: Ward {most_improved_ward} had a {max_weekly_rate_change_percent}% increase in the number of households responding compared to last week (Your Ward is at {round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0]*100,2)}%).

Overall, {total_reported_perc}% of all Chicagoans have responded to the Census. There are about {int(households_left):,} households left to count in Chicago.

Remember, for every additional person counted in Chicago, we stand to gain approximately $1,400 that could be used towards parks, schools, and infrastructure!

*Target rates are based on each ward’s 2010 Census response rate and a city overall target of 75% response.

'''
"""

    if if_platform_user == 'Yes':
        email_body2 = """ +
'''
Find out more at the [Census Intelligence Center](https://platform.civisanalytics.com/spa/#/reports/services/77574?fullscreen=true)'''
"""

    try:
        email_body = email_body1 + email_body2
    except:
        email_body = email_body1

    return email_body


#Create function that defines the "source script" of the new script that get generated (sends to ward emails)
def create_source_script(ward_number, ward_email_data, ward_agg, ward_weekly_rate_df, ward_stats):
    source_str = f"""import os \n
import civis \n
from datetime import date \n

client = civis.APIClient()

client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Weekly Census Report: Ward {ward_number}, {dt.date.today().strftime("%m/%d/%Y")}',
        'success_email_body' : {create_email_body(ward_number,ward_agg, ward_weekly_rate_df, ward_stats, ward_email_data[ward_email_data['WARD']==ward_number]['Platform User'].values[0])},
        'success_email_addresses' : ['{ward_email_data[ward_email_data['WARD']==ward_number]['Ward_Office_Email'].values[0]}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(client, ward_number, ward_email_data, ward_agg, ward_weekly_rate_df, ward_stats):
    new_script = client.scripts.post_python3(name = 'Ward_'+str(ward_number) + '_script',
                                source = create_source_script(ward_number,ward_email_data, ward_agg, ward_weekly_rate_df, ward_stats))
    return new_script
