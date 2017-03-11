#!/usr/bin/python

import ConfigParser, datetime, psycopg2
from subprocess import Popen, PIPE

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()

now = datetime.datetime.now()
month = now.month
opmonth = month - 1
year = now.year
opyear = now.year
if opmonth == 0:
    opmonth = 12
    opyear = year - 1

# Update the current period to be ready for incremental updates to speed up querying
query = """UPDATE gas_usage_monthly SET (btu, complete, timestamp) = (0, 'no', '%s 00:00:00') WHERE month = %s;""" % (now.strftime('%Y-%m-%d'), month)
cursor.execute(query)
db.commit()

query = """SELECT date_part('day', min(measurement_time)) = 1, date_part('day', max(measurement_time)) = num_days(%s,%s), max(tdiff) < 300  FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s;""" % (opyear, opmonth, opmonth, opyear)
cursor.execute(query)
data = cursor.fetchall()
mmin, mmax, maxint = zip(*data)
if mmin[0] and mmax[0] and maxint[0]:
    complete = 'yes'
else:
    complete = 'no'

# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
#query = """UPDATE gas_usage_monthly SET btu = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s) WHERE month = %s;""" % (opmonth, opyear, opmonth)
#query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s;""" % (opmonth, opyear)
query = """SELECT * FROM get_gas_usage('{0}-{1}-01', '{2}-{3}-01');""".format(opyear, opmonth, year, month) 
proc = Popen("""/usr/bin/R --vanilla --slave --args "%s" < /home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R""" % (query), shell=True, stdout=PIPE, stderr=PIPE)
procout = proc.communicate()
btu = procout[0].split(' ')[1].replace('\n','')
query = """UPDATE gas_usage_monthly SET btu = %s WHERE month = %s;""" % (btu, opmonth)
cursor.execute(query)
#query = """UPDATE gas_usage_monthly SET btu_avg = (SELECT AVG(btu) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE date_part('month', measurement_time) = %s GROUP BY date_part('year', measurement_time)) AS x) WHERE month = %s;""" % (opmonth, opmonth)
#cursor.execute(query)
query = """UPDATE gas_usage_monthly SET complete = '%s' WHERE month = %s;""" % (complete, opmonth)
cursor.execute(query)
query = """UPDATE gas_usage_monthly SET timestamp = CURRENT_TIMESTAMP WHERE month = %s;""" % (opmonth)
cursor.execute(query)

# And finish it off
cursor.close()
db.commit()
db.close()

