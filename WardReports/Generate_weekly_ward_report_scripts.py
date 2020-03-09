import pandas as pd
import civis
import datetime as dt
import math
import os

client = civis.APIClient()

#actual ward table import to be used once testing is complete
'''
ward_email_data = civis.io.read_civis(database='City of Chicago',
                                      table = 'scratch.ward_office_info',
                                      use_pandas = True)
                                      '''

#Generate fake table that should be replaced with actual ward table later
wards = list(range(1,51))
emails = ['sundipta@gmail.com' for i in range(50)]
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

#Function to create
def create_email_body(ward_number):
    email_body = f"""
    '''
![City of Chicago Logo](https://raw.githubusercontent.com/Chicago/census2020_ward_rpt/civis_SR_branch/WardReports/LOGO-CHICAGO-horizontal.png)


Dear Ward {ward_number},

Today is Week {weeks_of_census()} of the Census Response Period. As of today, 2,000 households in your ward have responded to the 2020 Census. This means there are about **24,000 households** left to count!

Here are some additional facts about how Chicago wards are doing.

* **Best performer** *: Ward 3 has had 21% of all its households respond so far (Your Ward is at 15%)

* **Most improved**: Ward 20 had a 21% increase in the number of households responding compared to last week (Your Ward is at 10%).

Overall, 20% of all Chicagoans have responded to the Census. There are about 840,000 households left to count in Chicago.

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

j = {ward_number}

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
for i in range(1,2):
    temp_job_id = create_new_email_script(i)['id']
    print(temp_job_id)
    run_job_report = client.scripts.post_python3_runs(temp_job_id)
    print(run_job_report)
