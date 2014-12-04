if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT day_of_week AS label, dow, btu, btu_avg, complete FROM gas_usage_dow WHERE NOT dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY timestamp;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT day_of_week AS label, dow, btu, btu_avg, complete, timestamp FROM gas_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# create object updatequery as a dummy to skip getting commandArgs in the sourced file below
updatequery <- 1

# Summarize the current BTUs
query <- paste("SELECT * FROM get_gas_usage('", res1$timestamp, "', CURRENT_TIMESTAMP::timestamp);", sep='')
btu <- source('/home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R')$value
res1$btu <- res1$btu + btu

# Update the current hour
query <- paste("UPDATE gas_usage_dow SET (btu, timestamp) = (", res1$btu, ", CURRENT_TIMESTAMP) WHERE dow = ", res1$dow, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:5])

res$btu <- res$btu / 1000

fname <- '/var/www/electricity/ng_dow.png'
title <- "Furnace BTUs Used in the Last Week"
label.x <- "Day"
label.y <- "BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
