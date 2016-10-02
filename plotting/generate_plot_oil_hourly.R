if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

# Get historic data
query <- "SELECT u.hour AS label, u.btu, s.btu_avg, u.complete FROM oil_usage_hourly u INNER JOIN oil_statistics_hourly s ON u.hour=s.hour WHERE NOT u.hour = date_part('hour', CURRENT_TIMESTAMP) ORDER BY u.updated;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT u.hour AS label, u.btu, s.btu_avg, u.complete, u.updated FROM oil_usage_hourly u INNER JOIN oil_statistics_hourly s ON u.hour=s.hour WHERE u.hour = date_part('hour', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# create object updatequery as a dummy to skip getting commandArgs in the sourced file below
updatequery <- 1

# Summarize the current BTUs
query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
res2 <- dbGetQuery(con,query)
res1$btu <- res1$btu + res2$btu

# Update the current hour
query <- paste("UPDATE oil_usage_hourly SET (btu, updated) = (", res1$btu, ",'", res2$updated "') WHERE hour = ", res1$label, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:4])

# Do some sunrise and sunset calculations
today <- Sys.Date()
yesterday <- today - 1
currenthour <- res$label[24]
query3 <- paste("SELECT sunrise, sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res3 <- dbGetQuery(con, query3)
risehour <- as.numeric(strftime(strptime(res3$sunrise, format='%H:%M:%S'), format="%H"))
sethour <- as.numeric(strftime(strptime(res3$sunset, format='%H:%M:%S'), format="%H"))
if (risehour > currenthour) {
    query4 <- paste("SELECT sunrise FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunrise <- dbGetQuery(con, query4)[1,1]
} else {
    sunrise <- res3$sunrise
}
if (sethour > currenthour) {
    query4 <- paste("SELECT sunset FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunset <- dbGetQuery(con, query4)[1,1]
} else {
    sunset <- res3$sunset
}

fname <- '/var/www/electricity/ng_hourly.png'
title <- "Boiler BTUs in the Last Day"
label.x <- "Hour"
label.y <- "BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

