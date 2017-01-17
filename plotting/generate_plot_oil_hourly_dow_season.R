if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT u.hour AS label, u.btu, s.btu_avg, u.complete FROM oil_usage_hourly u INNER JOIN oil_statistics.oil_statistics_hourly_dow_season s ON u.hour=s.hour AND s.dow = CASE WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN date_part('dow', (CURRENT_TIMESTAMP - interval '1 day')) ELSE date_part('dow', CURRENT_TIMESTAMP) END AND s.season = CASE WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN (SELECT season FROM meteorological_season WHERE doy = date_part('doy', (CURRENT_TIMESTAMP - interval '1 day'))) ELSE (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP)) END WHERE NOT u.hour = date_part('hour', CURRENT_TIMESTAMP) ORDER BY u.updated;"
res <- dbGetQuery(con, query)

query2 <- "SELECT date_part('hour', CURRENT_TIMESTAMP) AS label, u.btu, s.btu_avg, complete FROM oil_usage_hourly u INNER JOIN oil_statistics.oil_statistics_hourly_dow_season s ON u.hour=s.hour WHERE u.hour = date_part('hour', CURRENT_TIMESTAMP) AND s.season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP)) AND dow = date_part('dow', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)

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

res$btu <- res$btu / 1000
res$btu_avg <- res$btu_avg / 1000

fname <- '/var/www/electricity/ng_hourly_dow_season.png'
title <- "Boiler BTUs in the Last Day"
label.x <- "Hour"
label.y <- "Thousand BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y, sunrise, sunset)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

