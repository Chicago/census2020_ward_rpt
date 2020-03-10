import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

from helpers import *
#########################################################
#Pulling in data for email (to be transferred to a different script later)

client = civis.APIClient()

def main():
    #actual ward table import to be used once testing is complete
    '''
    ward_email_data = civis.io.read_civis(database='City of Chicago',
                                          table = 'scratch.ward_office_info',
                                          use_pandas = True)
                                          '''

    #Generate fake table that should be replaced with actual ward table later
    wards = list(range(1,51))
    emails = ['srao@civisanalytics.com' for i in range(50)]
    platform_user = ['Yes' for i in range(25)] + ['No' for i in range(25)]
    ward_email_data = pd.DataFrame(list(zip(wards, emails, platform_user)),
                   columns =['WARD', 'Ward_Office_Email', 'Platform User'])


    #Pull ward aggregation and household data
    query = """SELECT * FROM cic.ward_visualization_table;"""
    ward_agg = civis.io.read_civis_sql(query,database='City of Chicago',use_pandas = True)
    ward_agg.dropna(inplace=True)

    #Calculate counted and uncounted households per ward
    ward_agg['Counted Households'] = round(ward_agg['mail_return_rate_cen_2010'] * (ward_agg['tot_housing_units_acs_13_17']/100))
    ward_agg['Uncounted Households'] = ward_agg['tot_housing_units_acs_13_17'] - ward_agg['Counted Households']
    ward_agg['Percent Counted'] = round(ward_agg['Counted Households']*100/ward_agg['tot_housing_units_acs_13_17'],1)
    ward_agg['Percent Uncounted'] = round(ward_agg['Uncounted Households']*100/ward_agg['tot_housing_units_acs_13_17'],1)


    #Pull daily response rate data
    query = """SELECT rates.gidtr, rates.date, rates.rate, viz.ward
                FROM cic.daily_response_rates_2010 as rates
                JOIN cic.visualization_table as viz
                ON viz.gidtr=rates.gidtr"""
    drate_j_ward = civis.io.read_civis_sql(query,database='City of Chicago',use_pandas = True)
    drate_j_ward.dropna(inplace=True)

    drate_j_ward['date'] = pd.to_datetime(drate_j_ward['date'])

    #real dates to be used later
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

    #Calculate most improved ward and the rate improvement
    max_weekly_rate_change = ward_weekly_rate_df["Rate_Change"].max()
    max_weekly_rate_change_percent = round(max_weekly_rate_change*100,1)
    most_improved_ward = ward_weekly_rate_df[ward_weekly_rate_df["Rate_Change"] == max_weekly_rate_change]["WARD"].values[0]

    ward_stats = {"max_change" : max_weekly_rate_change,
                    "max_change_percent" = max_weekly_rate_change_percent,
                    "most_improved_ward" = most_improved_ward}
    ##################################################################
    #Loop that calls function that makes new script per ward
    for i in range(25,27):
        temp_job_id = create_new_email_script(client, i, ward_email_data, ward_agg, ward_stats)['id']
        run_job_report = client.scripts.post_python3_runs(temp_job_id)

if __name__ == '__main__':
    main()
