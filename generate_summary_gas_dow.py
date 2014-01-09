#!/usr/bin/python

import argparse, datetime, psycopg2
from subprocess import Popen, PIPE

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_dow.py")
p.add_argument('-date', dest="rundate", required=False, help="The date to run in format 'YYYY-MM-DD'.")
args = p.parse_args()

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

# Set the appropriate opdate 
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    now = opdate + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)

nowdow = now.isoweekday()
if nowdow == 7:
    nowdow = 0

dow = opdate.isoweekday()
if dow == 7:
    dow = 0

# Update the current period to be ready for incremental updates to speed up querying if running as cron
if not args.rundate:
    query = """UPDATE gas_usage_dow SET (btu, complete, timestamp) = (0, 'no', '%s 00:00:00') WHERE dow = %s;""" % (now.strftime('%Y-%m-%d'), nowdow)
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

# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
#query = """UPDATE gas_usage_dow SET btu = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s') WHERE dow = %s;""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), dow)
query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s';""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
proc = Popen("""/usr/bin/R --vanilla --slave --args "%s" < /home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R""" % (query), shell=True, stdout=PIPE, stderr=PIPE)
procout = proc.communicate()
btu = procout[0].split(' ')[1].replace('\n','')
query = """UPDATE gas_usage_dow SET btu = %s WHERE dow = %s;""" % (btu, dow)
cursor.execute(query)
#query = """UPDATE gas_usage_dow SET btu_avg = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE tdiff <= 86400 AND measurement_time >= '2013-03-22' AND date_part('dow', measurement_time) = %s GROUP BY date_part('year', measurement_time), date_part('doy', measurement_time)) AS x) WHERE dow = %s;""" % (dow, dow)
#cursor.execute(query)
query = """UPDATE gas_usage_dow SET complete = '%s' WHERE dow = %s;""" % (complete, dow)
cursor.execute(query)
if args.rundate:
    query = """UPDATE gas_usage_dow SET timestamp = '%s 00:00:01' WHERE dow = %s;""" % (now.strftime('%Y-%m-%d'), dow)
else:
    query = """UPDATE gas_usage_dow SET timestamp = CURRENT_TIMESTAMP WHERE dow = %s;""" % (dow)
cursor.execute(query)

# Now finish it off
cursor.close()
db.commit()
db.close()

