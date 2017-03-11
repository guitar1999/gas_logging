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
dbport = config.get('pidb', 'DBPORT')


# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
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
    # Boiler info
    query = """SELECT ROUND(btu, 2) AS btu, ROUND(gallons, 2) AS gallons, ROUND(kwh, 2) AS kwh, boiler_cycles, ROUND(total_boiler_runtime, 2) AS total_boiler_runtime, ROUND(avg_boiler_runtime, 2) AS avg_boiler_runtime, ROUND(min_boiler_runtime, 2) AS min_boiler_runtime, ROUND(max_boiler_runtime, 2) AS max_boiler_runtime FROM boiler_summary('{0} 00:00:00', '{0} 23:59:59')""".format(opdate.strftime('%Y-%m-%d'))
    cursor.execute(query)
    data = cursor.fetchall()
    btu, gallons, kwh, boiler_cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime = data[0]
    # Circulator info
    query = """SELECT circulator_cycles, ROUND(total_circulator_runtime, 2) AS total_circulator_runtime, ROUND(avg_circulator_runtime, 2) AS avg_circulator_runtime, ROUND(min_circulator_runtime, 2) AS min_circulator_runtime, ROUND(max_circulator_runtime, 2) AS max_circulator_runtime FROM circulator_summary('{0} 00:00:00', '{0} 23:59:59')""".format(opdate.strftime('%Y-%m-%d'))
    cursor.execute(query)
    data = cursor.fetchall()
    circulator_cycles, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime = data[0]
    # Insert it into the db
    query = """INSERT INTO boiler_daily_statistics (date, btu, gallon, kwh, boiler_cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime, circulator_cycles, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime, updated) VALUES ('{0}', {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, CURRENT_TIMESTAMP);""".format(opdate.strftime('%Y-%m-%d'), btu, gallons, kwh, boiler_cycles, total_boiler_runtime, avg_boiler_runtime, min_boiler_runtime, max_boiler_runtime, circulator_cycles, total_circulator_runtime, avg_circulator_runtime, min_circulator_runtime, max_circulator_runtime)
    cursor.execute(query)
    db.commit()
    status = """Boiler: {0}h, {1} cycles, mean of {2} min/cycle. Circulator: {3}h, {4} cycles, mean of {5} min/cycle. {6} btu, {7} gal, {8} kwh.""".format(round(total_boiler_runtime / 60, 1), boiler_cycles, round(avg_boiler_runtime, 1), round(total_circulator_runtime / 60, 1), circulator_cycles, round(avg_circulator_runtime, 1), round(btu, 0), round(gallons, 1), round(kwh, 1))
    if not args.rundate:
        # status = """Boiler: {0}h, {1} cycles, mean of {2} min/cycle. Circulator: {3}h, {4} cycles, mean of {5} min/cycle. {6} btu, {7} kwh.""".format(round(total_boiler_runtime / 60, 1), boiler_cycles, round(avg_boiler_runtime, 1), round(total_circulator_runtime / 60, 1), circulator_cycles, round(avg_circulator_runtime, 1), round(btu, 0), round(kwh, 1))
        tweet(status)
    else:
        print(status)

# Close database connection
cursor.close()  
db.close()
