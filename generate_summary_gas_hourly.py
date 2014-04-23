#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2, sys
from subprocess import Popen, PIPE

# Allow the script to be run on a specific hour and day of the week
p = argparse.ArgumentParser(prog="generate_summary_gas_hourly.py")
p.add_argument('-hour', dest="runhour", required=False, help="The hour to run.")
p.add_argument('-date', dest="rundate", required=False, help="The date to run in format 'YYYY-MM-DD'.")
args = p.parse_args()


# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()

if args.runhour:
    if args.runhour != '23':
        hour = int(args.runhour) + 1
        now = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    else:
        hour = 0
        now = datetime.datetime.strptime(args.rundate, '%Y-%m-%d') + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    hour = now.hour

if hour == 0:
    ophour = 23
    opdate = now - datetime.timedelta(1)
else:
    ophour = hour - 1
    opdate = now
dow = opdate.isoweekday()
# Make sunday 0 to match postgres style rather than python style
if dow == 7:
    dow = 0

# Now update the current period to be ready for incremental updates to speed up querying
if not args.runhour:
    query = """UPDATE gas_usage_hourly SET (btu, complete, timestamp) = (0, 'no', '%s:00:00') WHERE hour = %s;""" % (now.strftime('%Y-%m-%d %H'), hour)
    cursor.execute(query)
    db.commit()

# Check to see if the data are complete
query = """SELECT max(tdiff) < 300  FROM electricity_measurements WHERE measurement_time > '%s' AND date_part('hour', measurement_time) = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour)
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'


#Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
if args.runhour:
    query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > '%s' AND measurement_time <= '%s' AND date_part('hour', measurement_time) = %s;""" % (opdate.strftime('%Y-%m-%d'), opdate.strftime('%Y-%m-%d 23:59:59.999999'), ophour)
else:
    query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > '%s' AND date_part('hour', measurement_time) = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour)
proc = Popen("""/usr/bin/R --vanilla --slave --args "%s" < /home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R""" % (query), shell=True, stdout=PIPE, stderr=PIPE)
procout = proc.communicate()
btu = procout[0].split(' ')[1].replace('\n','')
query = """UPDATE gas_usage_hourly SET btu = %s WHERE hour = %s;""" % (btu, ophour)
cursor.execute(query)

#query = """UPDATE gas_usage_hourly SET btu_avg = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE tdiff <= 3600 AND measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, ophour)
#cursor.execute(query)
#query = """UPDATE gas_usage_hourly SET btu_avg_dow = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE tdiff <= 3600 AND measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s AND date_part('dow', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, dow, ophour)
#cursor.execute(query)
query = """UPDATE gas_usage_hourly SET complete = '%s' WHERE hour = %s;""" % (complete, ophour)
cursor.execute(query)
if args.rundate:
    query = """UPDATE gas_usage_hourly SET timestamp = '%s %s:00:01' WHERE hour = %s;""" % (now.strftime('%Y-%m-%d'), hour, ophour)
else:
    query = """UPDATE gas_usage_hourly SET timestamp = CURRENT_TIMESTAMP WHERE hour = %s;""" % (ophour)
cursor.execute(query)

# And finish it off
db.commit()
cursor.close()
db.close()
