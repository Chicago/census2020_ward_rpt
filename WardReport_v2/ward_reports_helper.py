import pandas as pd
import numpy as np

import datetime as dt
import math

import civis
import os

#Function to generate links to Chicago Ward Reports
def generate_report_link(ward_number, report_date, folder_name):
    if ward_number < 10:
        link = "http://webapps1.chicago.gov/censuswardreports/"+folder_name+"/Ward_0"+str(ward_number)+"_"+report_date+".html"
    if ward_number >= 10:
        link = "http://webapps1.chicago.gov/censuswardreports/"+folder_name+"/Ward_"+str(ward_number)+"_"+report_date+".html"
    return link

#autogenerate report and folder dates for link
def get_dates_for_link():
    today = dt.date.today()
    today_idx = today.weekday()
    sunday = today - dt.timedelta(1 + today_idx)
    monday = today - dt.timedelta(today_idx)
    report_date = monday.strftime('%Y-%m-%d')
    folder_name = monday.strftime('%Y-%m-%d')
    return {'Report Date':report_date,
            'Folder Name': folder_name}

#Function to create email_body in markdown
def create_email_body(ward_number, if_platform_user, report_date, folder_name):

    email_body1 = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal.png)


Dear Ward {ward_number},

Please find the link for your customized weekly Census Summary Snapshot, which contains:

 - Daily response plot with goal
 - Citywide ward map
 - Detailed ward map with tract level data
 - Census tract details for your ward

[{generate_report_link(ward_number,report_date,folder_name)}]({generate_report_link(ward_number,report_date,folder_name)})

Data is based on the Civis Intelligence Center. '''"""

    if if_platform_user=='Yes':
        email_body2 = """'''You can access the full intelligence here: [Census Intelligence Center](https://platform.civisanalytics.com/spa/#/reports/services/77574?fullscreen=true)
''' """

    email_body3 = """'''

Thank you!

Chicago Census Team

'''
"""
    try:
        email_body = email_body1 + email_body2 + email_body3
    except:
        email_body = email_body1 + email_body3

    return email_body


#Create function that defines the "source script" of the new script that get generated (sends to ward emails)
def create_source_script( ward_number,ward_email, if_platform_user, report_date, folder_name):
    source_str = f"""import os \n
import civis \n
from datetime import date \n
client = civis.APIClient()
client.scripts.patch_python3(os.environ['CIVIS_JOB_ID'], notifications = {{
        'success_email_subject' : 'Ward Census Summary: Ward {ward_number}',
        'success_email_body' : {create_email_body(ward_number, if_platform_user, report_date,folder_name)},
        'success_email_addresses' : ['{ward_email}']}})
        """
    return source_str


#Define function that creates new script
def create_new_email_script(client,ward_email_data, ward_number, if_platform_user, ward_email, report_date, folder_name):
    new_script = client.scripts.post_python3(name = 'City_Ward_'+str(ward_number) + '_Report',
                                source = create_source_script( ward_number, ward_email, if_platform_user, report_date, folder_name))
    return new_script
