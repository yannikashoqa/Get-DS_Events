# Get-DS_Events
Retrieve Deep Security Events

AUTHOR		: Yanni Kashoqa

TITLE		: Get-DSM_Events

DESCRIPTION	: This PowerShell script will list Deep Security Events based on search criteria

DISCLAIMER	: Please feel free to make any changes or modifications as seen fit.

FEATURES
- Search for all events based on time filters: LAST HOUR, LAST 24 HOURS, LAST 7 DAYS, LAST 30 DAYS, LAST 60 DAYS, LAST 90 DAYS
- Search for all events based on host filters: ALL_HOSTS
- Export to CSV Files

REQUIRMENTS
- PowerShell 3.0
- Create a DS-Config.json in the same folder with the following content modified to fit your environment:

{
    "MANAGER": "",
    "PORT": "",
    "TENANT": "",
    "USER_NAME": "",
    "PASSWORD": "",
    "REPORTNAME" : "DS_Events",
    "HOSTFILTERTYPE" : "0",
    "TIMEFILTERTYPE" : "5"
}

- For DSaaS, MANAGER should be "app.deepsecurity.trendmicro.com" and the PORT is "443".
- For Deep Security On-Premise, the MANAGER should be the FQDN of the DSM server and the PORT is "4119".
- The TENANT is used when connecting to DSaaS and should reflect your Tenant name.
- TIMEFILTERTYPE can be any of the following numeric values:
    - 0	LAST_HOUR
    - 1	LAST_24_HOURS
    - 2	LAST_7_DAYS
    - 5 LAST 30 DAYS
    - 6 LAST 60 DAYS
    - 7 LAST 90 DAYS