import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

from helpers import *

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
    ward_df = civis.io.read_civis_sql(query,database='City of Chicago',use_pandas = True)
    ward_df.dropna(inplace=True)

    #Calculate counted and uncounted households per ward
    ward_df['Counted Households'] = round(ward_df['mail_return_rate_cen_2010'] * (ward_df['tot_occp_units_acs_13_17']/100))
    ward_df['Uncounted Households'] = ward_df['tot_occp_units_acs_13_17'] - ward_df['Counted Households']
    ward_df['Percent Counted'] = round(ward_df['Counted Households']*100/ward_df['tot_occp_units_acs_13_17'],1)
    ward_df['Percent Uncounted'] = round(ward_df['Uncounted Households']*100/ward_df['tot_occp_units_acs_13_17'],1)

    #Calculate most improved ward and the rate improvement
    total_reported_perc = round(ward_df['Counted Households'].sum()*100/ward_df['tot_occp_units_acs_13_17'].sum(),1)
    households_left = ward_df['Uncounted Households'].sum()

    #Pull daily response rate data and aggregate by week
    ward_weekly_rate_df = get_weekly_rate_df()

    best_performer = int(ward_df[ward_df['Percent Counted']==ward_df['Percent Counted'].max()]['ward'].values[0])
    max_weekly_rate_change = ward_weekly_rate_df["Rate_Change"].max()
    max_weekly_rate_change_percent = round(max_weekly_rate_change*100,1)
    most_improved_ward = ward_weekly_rate_df[ward_weekly_rate_df["Rate_Change"] == max_weekly_rate_change]["WARD"].values[0]

    stats = { "total_reported_perc" : total_reported_perc,
                    "households_left" : households_left,
                    "best_performer": best_performer,
                    "max_change" : max_weekly_rate_change,
                    "max_change_percent" : max_weekly_rate_change_percent,
                    "most_improved_ward" : most_improved_ward}

    ##################################################################
    #Loop that calls function that makes new script per ward
    for ward_number in range(25,27):
        temp_job_id = create_new_email_script(client, ward_number, ward_email_data, ward_df, ward_weekly_rate_df, stats)['id']
        run_job_report = client.scripts.post_python3_runs(temp_job_id)

if __name__ == '__main__':
    main()
