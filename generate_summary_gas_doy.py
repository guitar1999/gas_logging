#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2
from subprocess import Popen, PIPE

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_doy.py")
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


if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    now = opdate + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)

doy = opdate.timetuple().tm_yday
dow = opdate.isoweekday()
# Make sunday 0 to match postgres style rather than python style
if dow == 7:
    dow = 0


# Now update the current period to be ready for incremental updates to speed up querying
if not args.rundate:
    query = """UPDATE gas_usage_doy SET (btu, complete, timestamp) = (0, 'no', '%s 00:00:00') WHERE doy = %s;""" % (now.strftime('%Y-%m-%d'), now.timetuple().tm_yday)
    cursor.execute(query)
    db.commit()

# Check to see if the data are complete
query = """SELECT max(tdiff) < 300  FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s';""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'

#Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
#query = """UPDATE gas_usage_doy SET btu = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s') WHERE doy = %s;""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), doy)
query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s';""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
proc = Popen("""/usr/bin/R --vanilla --slave --args "%s" < /home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R""" % (query), shell=True, stdout=PIPE, stderr=PIPE)
procout = proc.communicate()
btu = procout[0].split(' ')[1].replace('\n','')
query = """UPDATE gas_usage_doy SET btu = %s WHERE doy = %s;""" % (btu, doy)
cursor.execute(query)
# Using dow for now since we don't have any historical doy data until March 14, 2014
#if opdate > datetime.datetime(2014,3,14,0,0,0):
#    query = """UPDATE gas_usage_doy SET btu_avg = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE tdiff <= 86400 AND measurement_time >= '2013-03-22' AND date_part('doy', measurement_time) = %s GROUP BY date_part('year', measurement_time)) AS x) WHERE doy = %s;""" % (doy, doy)
#else:
#    query = """UPDATE gas_usage_doy SET btu_avg = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE tdiff <= 86400 AND measurement_time >= '2013-03-22' AND date_part('dow', measurement_time) = %s GROUP BY date_part('year', measurement_time), date_part('doy', measurement_time)) AS x) WHERE doy = %s;""" % (dow, doy)
#cursor.execute(query)
query = """UPDATE gas_usage_doy SET complete = '%s' WHERE doy = %s;""" % (complete, doy)
cursor.execute(query)
if args.rundate:
    query = """UPDATE gas_usage_doy SET timestamp = '%s 00:00:01' WHERE doy = %s;""" % (now.strftime('%Y-%m-%d'), doy)
else:
    query = """UPDATE gas_usage_doy SET timestamp = CURRENT_TIMESTAMP WHERE doy = %s;""" % (doy)
cursor.execute(query)

# And finish it off
cursor.close()
db.commit()
db.close()

