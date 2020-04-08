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
    query = """SELECT *
                FROM cic.ward_daily_rates_2020"""
    ward_daily_rates = civis.io.read_civis_sql(query, database = 'City of Chicago', use_pandas = True)
    ward_daily_rates.dropna(inplace = True)

    ward_daily_rates['response_date'] = pd.to_datetime(ward_daily_rates['response_date'])
    #2020 date ranges
    today = np.datetime64('today')
    last_week_end = np.datetime64('today') - np.timedelta64(7,'D')
    last_week_begin = last_week_end - np.timedelta64(7,'D')

    #test code for 2010 dates
    '''
    today = np.datetime64('2010-04-27')
    last_week_end = np.datetime64('2010-04-20')
    last_week_begin = np.datetime64('2010-04-13')
    '''

    #masks to select for weeks
    this_week_mask = (ward_daily_rates['response_date'] > last_week_end) & (ward_daily_rates['response_date'] <= today)
    last_week_mask = (ward_daily_rates['response_date'] > last_week_begin) & (ward_daily_rates['response_date'] <= last_week_end)

    #subsetting data by week
    this_week = ward_daily_rates.loc[this_week_mask]
    last_week = ward_daily_rates.loc[last_week_mask]

    ward_weekly_rates = []
    for i in range (1,51):
        ward = i
        this_week_rate = this_week.loc[(this_week['ward'] == ward)]['response_rate'].mean()
        last_week_rate = last_week.loc[(last_week['ward'] == ward)]['response_rate'].mean()
        if math.isnan(last_week_rate):
            last_week_rate = 0
        ward_weekly_rates.append({'WARD' : ward,
                                  "This Week Rate" : this_week_rate,
                                 "Last Week Rate" : last_week_rate})
    ward_weekly_rate_df = pd.DataFrame(ward_weekly_rates)
    ward_weekly_rate_df['Rate_Change'] = round((ward_weekly_rate_df["This Week Rate"]-ward_weekly_rate_df["Last Week Rate"])*100/ward_weekly_rate_df["Last Week Rate"],1)


    return ward_weekly_rate_df

#Create a function that returns a dictionary of all the household count stats per ward
def counted_per_ward(ward_agg, ward_number):
    subset = ward_agg[ward_agg['ward']==ward_number]
    counted = subset['counted_households'].values[0]
    uncounted = subset['uncounted_households'].values[0]
    per_counted = subset['percent_counted'].values[0]
    per_uncounted = subset['percent_uncounted'].values[0]
    per_to_target = subset['percent_to_target'].values[0]
    counted_dict = {"Num_Counted": counted,
                   "Num_Uncounted": uncounted,
                   "Perc_Counted": per_counted,
                   "Perc_Uncounted": per_uncounted,
                   "Perc_to_Target": per_to_target}
    return counted_dict

#Function to generate links to Chicago Ward Reports
def generate_report_link(ward_number, report_date, folder_name):
    if ward_number < 10:
        link = "http://webapps1.chicago.gov/censuswardreports/"+folder_name+"/Ward_0"+str(ward_number)+"_"+report_date+".html"
    if ward_number >= 10:
        link = "http://webapps1.chicago.gov/censuswardreports/"+folder_name+"/Ward_"+str(ward_number)+"_"+report_date+".html"
    return link

#Function to create email_body in markdown
def create_email_body(ward_number, ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user, report_date, folder_name):

    total_reported_perc = ward_stats["total_reported_perc"]
    households_left = ward_stats["households_left"]
    best_performer = ward_stats["best_performer"]
    most_improved_ward = ward_stats["most_improved_ward"]
    max_weekly_rate_change_percent = ward_stats["max_change_percent"]

    ward_email_rate = round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0],2)

    email_body1 = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal.png)


Dear Ward {ward_number},

Today is week {weeks_of_census()} of the Census Response Period. As of today, {int(counted_per_ward(ward_agg, ward_number)['Num_Counted']):,} households in your ward have responded to the 2020 Census. This means there are about **{int(counted_per_ward(ward_agg, ward_number)['Num_Uncounted']):,} households which have not responded**!

Your ward has a self-response rate of {counted_per_ward(ward_agg,ward_number)['Perc_Counted']}%. Overall, {total_reported_perc}% of all Chicagoans have responded to the Census, and Chicago’s target is a 75% self-response rate. There are about {int(households_left):,} households left in Chicago which have not responded.

Here are some additional facts about how Chicago wards are doing:

* **Best performer** *: Ward {best_performer} is at {ward_agg['percent_to_target'].max()}% of its target 2020 response rate '''"""
    if best_performer==ward_number:
        best_str = f"""+'''(Keep up the good work, ward {ward_number}!)

        '''"""
    else:
        best_str = f"""+'''(Your ward is at {counted_per_ward(ward_agg, ward_number)['Perc_to_Target']}% of your target)

        '''"""

    email_body2= f"""+
'''
* **Most improved**: Ward {most_improved_ward} had a {max_weekly_rate_change_percent}% increase in the number of households responding compared to last week '''"""
    if most_improved_ward==ward_number:
        improved_str = f"""+'''(Keep up the good work, ward {ward_number}!)

        '''"""
    else:
        improved_str = f"""+'''(Your ward's increase was {round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0],2)}%).

        '''"""

    email_body3= f"""+
'''
Remember, for every additional person counted in Chicago, we stand to gain approximately $1,400 that could be used towards parks, schools, and infrastructure!

Find out more in your personalized ward report [here]({generate_report_link(ward_number,report_date,folder_name)}).
''' """
    if if_platform_user == 'Yes':
        email_body_platform = """ +
'''Dig into the data at the [Census Intelligence Center](https://platform.civisanalytics.com/spa/#/reports/services/77574?fullscreen=true).
(Please open reports in Chrome or Firefox internet browser.)'''

"""
    else:
        email_body_platform = """ +
'''(Please open report in Chrome or Firefox internet browser.)'''

        """

    email_body4=f""" +
'''

*Target rates are based on each ward’s 2010 Census response rate and a city overall target of 75% response.

'''
"""



    try:
        email_body = email_body1 + best_str + email_body2 + improved_str + email_body3 + email_body_platform + email_body4
    except:
        email_body = email_body1 + best_str + email_body2 + improved_str + email_body3 + email_body4

    return email_body


#Create function that defines the "source script" of the new script that get generated (sends to ward emails)
def create_source_script(ward_number, ward_email, ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user, report_date, folder_name):
    source_str = f"""import os \n
import civis \n
from datetime import date \n

client = civis.APIClient()

client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Weekly Census Report: Ward {ward_number}, {dt.date.today().strftime("%m/%d/%Y")}',
        'success_email_body' : {create_email_body(ward_number,ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user, report_date, folder_name)},
        'success_email_addresses' : ['{ward_email}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(client, ward_number, ward_email, ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user, report_date, folder_name):
    new_script = client.scripts.post_python3(name = 'Ward_'+str(ward_number) + '_Report_Test',
                                source = create_source_script(ward_number,ward_email, ward_agg, ward_weekly_rate_df, ward_stats, if_platform_user, report_date, folder_name))
    return new_script
