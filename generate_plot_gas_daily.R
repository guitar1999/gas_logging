if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

# Get historic data
query <- "SELECT doy AS label, btu, btu_avg, complete FROM gas_usage_doy WHERE timestamp >= CURRENT_TIMESTAMP - interval '29 days' AND NOT timestamp IS NULL AND NOT doy = date_part('doy', CURRENT_TIMESTAMP) ORDER BY timestamp;" 
res <- dbGetQuery(con, query)

# Get current data
query <- "SELECT doy AS label, btu, btu_avg, complete, timestamp FROM gas_usage_doy WHERE doy = date_part('doy', CURRENT_TIMESTAMP);"
res1 <- dbGetQuery(con,query)

# create object updatequery as a dummy to skip getting commandArgs in the sourced file below
updatequery <- 1

# Summarize the current BTUs
query <- paste("SELECT * FROM get_gas_usage('", res1$timestamp, "', CURRENT_TIMESTAMP::timestamp);", sep='')
btu <- source('/home/jessebishop/scripts/gas_logging/gas_interval_summarizer.R')$value
res1$btu <- res1$btu + btu

# Update the current doy
query <- paste("UPDATE gas_usage_doy SET (btu, timestamp) = (", res1$btu, ", CURRENT_TIMESTAMP) WHERE doy = ", res1$label, ";", sep='')
dbGetQuery(con,query)

res <- rbind(res, res1[1,1:4])
res$jday <- res$label
today <- Sys.Date()
jday <- format(today, '%j')
year.this <- format(today, '%Y')
year.last <- as.numeric(year.this) - 1
res$label <- format(as.Date(res$label - 1, origin=paste(ifelse(res$label <= jday, year.this, year.last), '-01-01', sep='')), '%b-%d')


fname <- '/var/www/electricity/ng_daily.png'
title <- "Furnace BTUs in the Last Month"
label.x <- "Hour"
label.y <- "BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=2)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

