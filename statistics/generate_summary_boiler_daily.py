#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2
from tweet import *

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_boiler_daily.py")
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
    now = opdate + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)


# Check to see if the boiler is running
query = """SELECT status FROM boiler_status WHERE status_time = (SELECT MAX(status_time) FROM boiler_status WHERE status_time::date <= '{0}');""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
dstatus = cursor.fetchall()[0][0]
query = """SELECT COUNT(status) FROM boiler_status WHERE status_time::date = '{0}';""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
dcount = cursor.fetchall()[0][0]

# If the system is on, or if it had a state change today, then run the analysis
if dstatus == 'ON' or dcount > 0:
    # Current hack query to get boiler runtime. This will need to be adjusted once the system
    # is plumbed to the air handler or the heat is running at the same time.
    query = """WITH system_stats AS (SELECT event_group, system_status, SUM(tdiff) / 60 AS runtime, SUM(btu) AS btu, SUM(watts * tdiff / 1000 / 60 / 60) AS kwh FROM boiler_status({0}, {1}) GROUP BY event_group, system_status), system_stats_circulator AS (SELECT event_group, 'circulator2'::TEXT AS system_status, SUM(runtime) AS runtime, 0 AS btu, 0 AS kwh FROM system_stats WHERE system_status IN ('boiler and circulator', 'circulator') GROUP BY event_group) INSERT INTO oil_statistics.boiler_daily_statistics (date, btu, kwh, cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime, updated) SELECT '2016-04-22 00:00:00'::DATE, SUM(btu) AS total_btu, ROUND(SUM(kwh), 2) AS total_kwh, COUNT(DISTINCT event_group) AS cycles, ROUND(SUM(CASE WHEN system_status = 'boiler and circulator' THEN runtime END), 2) AS total_boiler_runtime, ROUND(AVG(CASE WHEN system_status = 'boiler and circulator' THEN runtime END), 2) AS avg_boiler_runtime, ROUND(MIN(CASE WHEN system_status = 'boiler and circulator' THEN runtime END), 2) AS min_boiler_runtime, ROUND(MAX(CASE WHEN system_status = 'boiler and circulator' THEN runtime END), 2) AS max_boiler_runtime, ROUND(SUM(CASE WHEN system_status = 'circulator2' THEN runtime END), 2) AS total_circulator_runtime, ROUND(AVG(CASE WHEN system_status = 'circulator2' THEN runtime END), 2) AS avg_circulator_runtime, ROUND(MIN(CASE WHEN system_status = 'circulator2' THEN runtime END), 2) AS min_circulator_runtime, ROUND(MAX(CASE WHEN system_status = 'circulator2' THEN runtime END), 2) AS max_circulator_runtime, CURRENT_TIMESTAMP FROM (SELECT * FROM system_stats UNION SELECT * FROM system_stats_circulator) AS x RETURNING btu, kwh, cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime;""".format(opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
    cursor.execute(query)
    db.commit()
    data = cursor.fetchall()
    btu, kwh, cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime = data[0]
    if not args.rundate:
        # Get the weather info
        query = """SELECT mean_dewpoint, mean_temperature FROM weather_daily_mean_data WHERE date = (CURRENT_TIMESTAMP - interval '1 day')::date;"""
        cursor.execute(query)
        data = cursor.fetchall()
        dew, t = data[0]

        # Tweet!
        status = """Boiler: total runtime {0} hours, {1} cycles, mean of {2} minutes per cycle. Circulator: total runtime {0} hours,.""".format(runtime, cycles, avg_run, t, dew)
        tweet(status)

# Close database connection
cursor.close()
db.close()
