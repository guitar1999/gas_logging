if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

# Get historic data
query <- "SELECT month AS label, btu, 0::INTEGER AS btu_avg, complete FROM oil_usage_monthly WHERE NOT month = date_part('month', CURRENT_TIMESTAMP) AND NOT updated IS NULL ORDER BY updated;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT month AS label, btu, 0::INTEGER AS btu_avg, complete, updated FROM oil_usage_monthly WHERE month = date_part('month', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# Summarize the current BTUs
query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
res2 <- dbGetQuery(con,query)
# Set to zero if NA
res2$btu[is.na(res2$btu)] <- 0
res1$btu <- res1$btu + res2$btu

# Update the current month
query <- paste("UPDATE oil_usage_monthly SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE month = ", res1$label, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:4])
res$btu <- res$btu / 1000000

fname <- '/var/www/electricity/ng_monthly.png'
title <- "Boiler BTUs Used in the Last Year"
label.x <- "Month"
label.y <- "Million BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, "207.38.86.222:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
