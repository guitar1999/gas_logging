import argparse, ConfigParser, datetime, psycopg2
from tweet import *

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_dow.py")
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

query = """SELECT ROUND(SUM(tdiff) / 60 / 60, 2) AS runtime FROM electricity_measurements WHERE watts_ch3 > 490 AND measurement_time::date = (CURRENT_TIMESTAMP - interval '1 day')::date;"""
cursor.execute(query)
data = cursor.fetchall()
runtime = data[0][0]

status = """The dehumidifier ran for {0} hours yesterday.""".format(runtime)
tweet(status)
