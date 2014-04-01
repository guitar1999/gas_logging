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

year = datetime.datetime.now().year - 1

# Update the current period to be ready for incremental updates to speed up querying
query = """INSERT INTO gas_usage_yearly (year, btu, complete, timestamp) VALUES (%s, 0, 'no', '%s-01-01 00:00:00');""" % (year + 1, year + 1)
cursor.execute(query)
db.commit()

query = """SELECT min(measurement_time)::date = '%s-01-01'::date, max(measurement_time)::date = '%s-12-31'::date, max(tdiff) < 300  FROM electricity_measurements WHERE date_part('year', measurement_time) = %s;""" % (year, year, year)
cursor.execute(query)
data = cursor.fetchall()
mmin, mmax, maxint = zip(*data)
if mmin[0] and mmax[0] and maxint[0]:
    complete = 'yes'
else:
    complete = 'no'

# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
#query = """UPDATE electricity_usage_yearly SET (btu, complete, timestamp) = ((SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS btu FROM electricity_measurements WHERE date_part('year', measurement_time) = %s), '%s', CURRENT_TIMESTAMP) WHERE year = %s;""" % (year, complete, year)
query = """SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE date_part('year', measurement_time) = %s AND NOT watts_ch3 IS NULL;""" % (year)
proc = Popen("""/usr/bin/R --vanilla --slave --args "%s" < /home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R""" % (query), shell=True, stdout=PIPE, stderr=PIPE)
procout = proc.communicate()
btu = procout[0].split(' ')[1].replace('\n','')
query = """UPDATE gas_usage_yearly SET (btu, complete, timestamp) = (%s, '%s', CURRENT_TIMESTAMP) WHERE year = %s;""" % (btu, complete, year)
cursor.execute(query)

# Now finish it off
cursor.close()
db.commit()
db.close()

