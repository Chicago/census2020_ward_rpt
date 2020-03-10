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
    weeks = math.floor(num_days/7)
    return weeks

#Create a function that returns a dictionary of all the household count stats per ward
def counted_per_ward(ward_agg, ward_number):
    counted = ward_agg[ward_agg['ward']==ward_number]['Counted Households'].values[0]
    uncounted = ward_agg[ward_agg['ward']==ward_number]['Uncounted Households'].values[0]
    per_counted = ward_agg[ward_agg['ward']==ward_number]['Percent Counted'].values[0]
    per_uncounted = ward_agg[ward_agg['ward']==ward_number]['Percent Uncounted'].values[0]
    counted_dict = {"Num_Counted": counted,
                   "Num_Uncounted": uncounted,
                   "Perc_Counted": per_counted,
                   "Perc_Uncounted": per_uncounted}
    return counted_dict

#Function to create email_body in markdown
def create_email_body(ward_number, ward_agg, if_platform_user):
    email_body1 = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal_mobile_friendly.png)


Dear Ward {ward_number},

Today is week {weeks_of_census()} of the Census Response Period. As of today, {int(counted_per_ward(ward_agg, ward_number)['Num_Counted']):,} households in your ward have responded to the 2020 Census. This means there are about **{int(counted_per_ward(ward_agg, ward_number)['Num_Uncounted']):,} households left to count**!

Here are some additional facts about how Chicago wards are doing:

* **Best performer** *: Ward {best_performer} has had {ward_agg['Percent Counted'].max()}% of all its households respond so far (Your Ward is at {counted_per_ward(ward_agg, ward_number)['Perc_Counted']}%)

* **Most improved**: Ward {most_improved_ward} had a {max_weekly_rate_change_percent}% increase in the number of households responding compared to last week (Your Ward is at {round(ward_weekly_rate_df[ward_weekly_rate_df['WARD']==ward_number]['Rate_Change'].values[0]*100,2)}%).

Overall, {total_reported_perc}% of all Chicagoans have responded to the Census. There are about {int(households_left):,} households left to count in Chicago.

Remember, for every additional person counted in Chicago, the City receives approximately $1,400 to put towards parks, schools, and infrastructure!

*Performance is measured based on how well each ward is performing relative to performance in the 2010 Census

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
def create_source_script(ward_number, ward_email_data, ward_agg):
    source_str = f"""import os \n
import civis \n
from datetime import date \n

client = civis.APIClient()

client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Weekly Census Report: Ward {ward_number}, {dt.date.today().strftime("%m/%d/%Y")}',
        'success_email_body' : {create_email_body(ward_number,ward_agg,ward_email_data[ward_email_data['WARD']==ward_number]['Platform User'].values[0])},
        'success_email_addresses' : ['{ward_email_data[ward_email_data['WARD']==ward_number]['Ward_Office_Email'].values[0]}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(client, ward_number, ward_email_data, ward_agg):
    new_script = client.scripts.post_python3(name = 'Ward_'+str(ward_number) + '_script',
                                source = create_source_script(ward_number,ward_email_data, ward_agg))
    return new_script
