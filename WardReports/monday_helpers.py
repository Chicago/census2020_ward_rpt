import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

#Function to generate links to Chicago Ward Reports
def generate_report_link(ward_number, report_date):
    if ward_number < 10:
        link = "http://Ward_0"+str(ward_number)+"_"+report_date+".html"
    if ward_number >= 10:
        link = "http://Ward_"+str(ward_number)+"_"+report_date+".html"
    return link

#Function to create email_body in markdown
def create_email_body(ward_number, report_date):

    email_body = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal.png)


Dear Ward {ward_number},

Find your custom ward report [here]({generate_report_link(ward_number,report_date)}).

'''
"""

    return email_body


#Create function that defines the "source script" of the new script that get generated (sends to ward emails)
def create_source_script(ward_email_data, ward_number, report_date):
    source_str = f"""import os \n
import civis \n
from datetime import date \n

client = civis.APIClient()

client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Ward Census Summary: Ward {ward_number}',
        'success_email_body' : {create_email_body(ward_number, report_date)},
        'success_email_addresses' : ['{ward_email_data[ward_email_data['WARD']==ward_number]['Ward_Office_Email'].values[0]}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(client,ward_email_data, ward_number, report_date):
    new_script = client.scripts.post_python3(name = 'City_Ward_'+str(ward_number) + '_Report',
                                source = create_source_script(ward_email_data, ward_number,report_date))
    return new_script
