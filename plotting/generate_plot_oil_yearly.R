if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

# Get historic data
query <- "SELECT year AS label, btu, complete FROM oil_usage_yearly WHERE NOT year = date_part('year', CURRENT_TIMESTAMP) AND NOT updated IS NULL ORDER BY updated;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT year AS label, btu, complete, updated FROM oil_usage_yearly WHERE year = date_part('year', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# Summarize the current BTUs
query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
res2 <- dbGetQuery(con,query)
# Set to zero if NA
res2$btu[is.na(res2$btu)] <- 0
res1$btu <- res1$btu + res2$btu

# Update the current year
query <- paste("UPDATE oil_usage_yearly SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE year = ", res1$label, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:3])

res$btu <- res$btu / 1000000

fname <- '/var/www/electricity/ng_yearly.png'
title <- "Boiler BTUs By Year"
label.x <- "Year"
label.y <- "Million BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
#bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "207.38.86.222:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

