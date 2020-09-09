import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

from ward_reports_helper import *

client = civis.APIClient()

def main():
    #actual ward table import to be used once testing is complete
    #"""
    ward_email_data = civis.io.read_civis(database='City of Chicago',
                                          table = 'cic.weekly_email_list',
                                          use_pandas = True)
    """
    #Generate fake table that should be replaced with actual ward table later
    wards = list(range(1,51))
    emails = ['Gene.Leynes@cityofchicago.org ' for i in range(50)]
    platform_user = ['Yes' for i in range(25)] + ['No' for i in range(25)]
    ward_email_data = pd.DataFrame(list(zip(wards, emails, platform_user)),
                   columns =['WARD', 'Ward_Office_Email', 'platform_user'])
    #"""

    #report_date = "2020-04-05"
    #folder_name = "2020-04-06"
    report_date = get_dates_for_link()['Report Date']
    folder_name = get_dates_for_link()['Folder Name']

    ##################################################################
    #Loop that calls function that makes new script per ward
    for i in range(ward_email_data.shape[0]):
        ward_number = ward_email_data.iloc[i]['WARD']
        platform_user = ward_email_data.iloc[i]['platform_user']
        ward_email = ward_email_data.iloc[i]['Ward_Office_Email']
        temp_job_id = create_new_email_script(client, ward_email_data,ward_number, platform_user,ward_email, report_date,folder_name)['id']
        run_job_report = client.scripts.post_python3_runs(temp_job_id)
        print(ward_number, ward_email, platform_user, temp_job_id)

if __name__ == '__main__':
    main()
