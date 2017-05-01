if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT u.day_of_week AS label, u.dow, u.btu, s.btu_avg, u.complete FROM oil.oil_usage_dow u INNER JOIN oil_statistics.oil_statistics_dow s ON u.dow=s.dow WHERE NOT u.dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY u.updated;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT u.day_of_week AS label, u.dow, u.btu, s.btu_avg, u.complete, u.updated FROM oil.oil_usage_dow u INNER JOIN oil_statistics.oil_statistics_dow s ON u.dow=s.dow WHERE u.dow = date_part('dow', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# Summarize the current BTUs
query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
res2 <- dbGetQuery(con,query)
res2$btu[is.na(res2$btu)] <- 0
res1$btu <- res1$btu + res2$btu

# Update the current hour
query <- paste("UPDATE oil.oil_usage_dow SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE dow = ", res1$dow, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:5])

res$btu <- res$btu / 1000

fname <- '/var/www/electricity/ng_dow.png'
title <- "Boiler BTUs Used in the Last Week"
label.x <- "Day"
label.y <- "Thousand BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, "207.38.86.222:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
