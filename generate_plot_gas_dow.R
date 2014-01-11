if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT day_of_week AS label, dow, btu, btu_avg, complete FROM gas_usage_dow WHERE NOT dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY timestamp;"
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT day_of_week AS label, btu, btu_avg, complete, timestamp, dow FROM gas_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# create object updatequery as a dummy to skip getting commandArgs in the sourced file below
updatequery <- 1

# Summarize the current BTUs
query <- paste("SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > '", res1$timestamp, "' AND date_part('dow', measurement_time) = ", res1$dow, ";", sep='')
btu <- source('/home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R')$value
res1$btu <- res1$btu + btu

# Update the current hour
query <- paste("UPDATE gas_usage_dow SET (btu, timestamp) = (", res1$btu, ", CURRENT_TIMESTAMP) WHERE dow = ", res1$dow, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:4])


fname <- '/var/www/electricity/ng_dow.png'
title <- "Furnace BTUs Used in the Last Week"
label.x <- "Day"
label.y <- "BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
