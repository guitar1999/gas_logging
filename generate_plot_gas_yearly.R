if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

# Get historic data
query <- "SELECT year AS label, btu, complete FROM gas_usage_yearly WHERE NOT year = date_part('year', CURRENT_TIMESTAMP) AND NOT timestamp IS NULL ORDER BY timestamp;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT year AS label, btu, complete, timestamp FROM gas_usage_yearly WHERE year = date_part('year', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# create object updatequery as a dummy to skip getting commandArgs in the sourced file below
updatequery <- 1

# Summarize the current BTUs
query <- paste("SELECT * FROM get_gas_usage('", res1$timestamp, "', CURRENT_TIMESTAMP::timestamp);", sep='')
btu <- source('/home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R')$value
res1$btu <- res1$btu + btu

# Update the current year
query <- paste("UPDATE gas_usage_yearly SET (btu, timestamp) = (", res1$btu, ", CURRENT_TIMESTAMP) WHERE year = ", res1$label, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:3])

res$btu <- res$btu / 1000000

fname <- '/var/www/electricity/ng_yearly.png'
title <- "Electricity Usage By Year"
label.x <- "Year"
label.y <- "Million BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, xlab=label.x, ylab=label.y)
#bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

