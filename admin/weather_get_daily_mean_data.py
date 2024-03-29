#!/usr/bin/python

import argparse
import ConfigParser
import datetime
import json
import os
import psycopg2
import urllib2

p = argparse.ArgumentParser(description='Downloads mean weather observations for yesterday and inserts them into the database')
p.add_argument('-d', '--date', dest='rundate', required=False, help='''Optionally provide a date for data download in the format 'YYYY-MM-DD'.''')
args = p.parse_args()

# Set the date
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
else:
    opdate = datetime.datetime.now() - datetime.timedelta(1)

# Get the api key from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
apikey = config.get('wunderground', 'APIKEY')

# Connect to wunderground and get historical_data
url = 'http://api.wunderground.com/api/{0}/history_{1}/q/USA/MA/East_Falmouth.json'.format(apikey, opdate.strftime('%Y%m%d'))
f = urllib2.urlopen(url)
json_string = f.read()
parsed_json = json.loads(json_string)

# Get the data (more later?)
hdd = parsed_json['history']['dailysummary'][0]['heatingdegreedays']
meandewpti = parsed_json['history']['dailysummary'][0]['meandewpti']
meanpressurei = parsed_json['history']['dailysummary'][0]['meanpressurei']
meantempi = parsed_json['history']['dailysummary'][0]['meantempi']
meanvisi = parsed_json['history']['dailysummary'][0]['meanvisi']
meanwdird = parsed_json['history']['dailysummary'][0]['meanwdird']
meanwindspdi = parsed_json['history']['dailysummary'][0]['meanwindspdi']

# Stick it in the database
db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()
query = """INSERT INTO weather_daily_mean_data (date, hdd, mean_dewpoint, mean_pressure, mean_temperature, mean_visibility, mean_wind_direction, mean_wind_speed) VALUES ('{0}', '{1}', {2}, {3}, {4}, {5}, {6}, {7});""".format(opdate.date(), hdd, meandewpti ,meanpressurei ,meantempi ,meanvisi ,meanwdird ,meanwindspdi)
cursor.execute(query)
db.commit()
cursor.close()
db.close()

