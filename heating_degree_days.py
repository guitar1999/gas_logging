#!/usr/bin/python

import argparse, datetime, json, psycopg2, urllib2

p = argparse.ArgumentParser(description='Downloads heating degree days for yesterday and inserts them into the database')
p.add_argument('-d', '--date', dest='rundate', required=False, help='''Optionally provide a date for data download in the format 'YYYY-MM-DD'.''')
args = p.parse_args()

# Set the date
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
else:
    opdate = datetime.datetime.now() - datetime.timedelta(1)

# Connect to wunderground and get historical_data
apikey = 'ee7f65f21cceab3a'
url = 'http://api.wunderground.com/api/{0}/history_{1}/q/USA/MA/East_Falmouth.json'.format(apikey, opdate.strftime('%Y%m%d'))
f = urllib2.urlopen(url)
json_string = f.read()
parsed_json = json.loads(json_string)

# Get the data (more later?)
hdd = parsed_json['history']['dailysummary'][0]['heatingdegreedays']

# Stick it in the database
db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()
query = """INSERT INTO weather_heat_deg_day (date, hdd) VALUES ('{0}', '{1}');""".format(opdate.date(), hdd)
cursor.execute(query)
db.commit()
cursor.close()
db.close()

