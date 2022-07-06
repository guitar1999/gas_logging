if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

# Get historic data
# query <- "SELECT u.hour AS label, u.btu, s.btu_avg, u.complete FROM oil_usage_hourly u INNER JOIN oil_statistics_hourly s ON u.hour=s.hour WHERE NOT u.hour = date_part('hour', CURRENT_TIMESTAMP) ORDER BY u.updated;"
query <- "SELECT label, runtime AS btu, runtime_avg AS btu_avg, complete FROM oil_plotting.oil_hourly_plot_view;"
res <- dbGetQuery(con, query)

# Get current data
# query <- "SELECT u.hour AS label, u.btu, s.btu_avg, u.complete, u.updated FROM oil_usage_hourly u INNER JOIN oil_statistics_hourly s ON u.hour=s.hour WHERE u.hour = date_part('hour', CURRENT_TIMESTAMP);"
# res1 <- dbGetQuery(con,query)

# Summarize the current BTUs
# query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
# res2 <- dbGetQuery(con,query)
# # Set to zero if NA
# res2$btu[is.na(res2$btu)] <- 0
# res1$btu <- res1$btu + res2$btu

# Update the current hour
# query <- paste("UPDATE oil_usage_hourly SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE hour = ", res1$label, ";", sep='')
# dbGetQuery(con,query)

# res <- rbind(res, res1[1,1:4])

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

# res$btu <- res$btu / 1000

fname <- '/tmp/ng_hourly.png'
title <- "Boiler Runtime in the Last Day"
label.x <- "Hour"
label.y <- "Runtime (Minutes)"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

