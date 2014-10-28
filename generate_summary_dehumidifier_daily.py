#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2
from tweet import *

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_dehumidifier_daily.py")
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

# Set rundate
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
else:
    opdate = datetime.datetime.now() - datetime.timedelta(1)

# Check to see if the dehumidifier is running
query = """SELECT status FROM dehumidifier_status WHERE status_time = (SELECT MAX(status_time) FROM dehumidifier_status WHERE status_time::date <= '{0}');""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
dstatus = cursor.fetchall()[0][0]
query = """SELECT COUNT(status) FROM dehumidifier_status WHERE status_time::date = '{0}';""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
dcount = cursor.fetchall()[0][0]

# If the system is on, or if it had a state change today, then run the analysis
if dstatus == 'ON' or dcount > 0:
    # Current hack query to get dehumidifier runtime. This will need to be adjusted once the system
    # is plumbed to the air handler or the heat is running at the same time.
    query = """INSERT INTO dehumidifier_daily_statistics (date, total_kwh, total_runtime_hours, avg_runtime_minutes, min_runtime_minutes, max_runtime_minutes, cycles) (SELECT '{0}'::date, round(sum(CASE WHEN status = 'OFF' OR status = 'ON' THEN kwh END), 2)AS kwh, round(sum(CASE WHEN status = 'ON' THEN runtime END) / 60, 2) AS total_hours, round(avg(CASE WHEN status = 'ON' THEN runtime END), 2) AS avg_minutes, round(min(CASE WHEN status = 'ON' THEN runtime END), 2) AS min_minutes, round(max(CASE WHEN status = 'ON' THEN runtime END), 2) AS max_minutes, count(CASE WHEN status = 'ON' THEN runtime END) AS cycles FROM (SELECT event_group, status, sum(tdiff) / 60 AS runtime, sum(kwh) AS kwh FROM (SELECT watts_ch3, tdiff, watts_ch3 * tdiff / 60 / 60 / 1000 AS kwh, measurement_time, status, CASE WHEN status = 'OFF' THEN NULL ELSE sum(CASE WHEN event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY measurement_time) END AS event_group FROM (SELECT watts_ch3, tdiff, measurement_time, status, CASE WHEN status = 'OFF' THEN NULL WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'OFF' THEN date_part('epoch', measurement_time ) WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'ON' THEN NULL END AS event_group FROM (SELECT watts_ch3, tdiff, measurement_time, CASE WHEN status = 'OFF' AND LAG(status) OVER (ORDER BY measurement_time) = 'ON' AND LEAD(status) OVER (ORDER BY measurement_time) = 'ON' THEN 'ON' ELSE status END AS status FROM (SELECT watts_ch3, tdiff, measurement_time, CASE WHEN watts_ch3 > 470 THEN 'ON'::text ELSE 'OFF'::text END AS status FROM electricity_measurements WHERE measurement_time::date = '{0}'::date) AS a) AS b) AS z ORDER BY measurement_time ASC) AS y GROUP BY event_group, status) AS x) RETURNING total_kwh, total_runtime_hours, avg_runtime_minutes, min_runtime_minutes, max_runtime_minutes, cycles;""".format(opdate.strftime('%Y-%m-%d'))
    cursor.execute(query)
    db.commit()
    data = cursor.fetchall()
    kwh, runtime, avg_run, min_run, max_run, cycles = data[0]
    if not args.rundate:
        # Get the weather info
        query = """SELECT mean_dewpoint, mean_temperature FROM weather_daily_mean_data WHERE date = (CURRENT_TIMESTAMP - interval '1 day')::date;"""
        cursor.execute(query)
        data = cursor.fetchall()
        dew, t = data[0]

        # Tweet!
        status = """Dehumidifier: total runtime {0} hours, {1} cycles, mean of {2} minutes per cycle. The mean temp was {3} and the mean dewpoint was {4}.""".format(runtime, cycles, avg_run, t, dew)
        tweet(status)

# Close database connection
cursor.close()
db.close()
