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
    """
    ward_email_data = civis.io.read_civis(database='City of Chicago',
                                          table = 'cic.weekly_email_list',
                                          use_pandas = True)
    """
    #Generate fake table that should be replaced with actual ward table later
    wards = list(range(1,51))
    emails = ['srao@civisanalytics.com' for i in range(50)]
    platform_user = ['Yes' for i in range(25)] + ['No' for i in range(25)]
    ward_email_data = pd.DataFrame(list(zip(wards, emails, platform_user)),
                   columns =['WARD', 'Ward_Office_Email', 'Platform User'])


    report_date = "2020-04-05"
    folder_name = "2020-04-06"

    ##################################################################
    #Loop that calls function that makes new script per ward
    for ward_number in range(1,51):
        ward_number = ward_email_data.iloc[i]['WARD']
        platform_user = ward_email_data.iloc[i]['platform_user']
        ward_email = ward_email_data.iloc[i]['Ward_Office_Email']
        temp_job_id = create_new_email_script(client, ward_email_data,ward_number,ward_email, report_date,folder_name)['id']
        run_job_report = client.scripts.post_python3_runs(temp_job_id)
        print(ward_email_data[ward_email_data['WARD']==ward_number]['Ward_Office_Email'].values[0])

if __name__ == '__main__':
    main()
