if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')
load('/home/jessebishop/scripts/gas_logging/data-furnace_model.RData')

# Get some data (This will be much more elegant with database integration)
query <- "SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 day' ORDER BY measurement_time;"
f <- dbGetQuery(con, query)

# Set a furnace status
f$status[f$watts < 60] <- 'blower'
f$status[f$watts < 40] <- 'off'
f$status[is.na(f$status)] <- 'on'
f$status[f$watts > 500] <- 'dehumidification'
# Now predict on the data
f$heatcall <- predict(m, f)
# Clean up bad values (a better training dataset will help here)
f$heatcall[f$heatcall < 40] <- 40
f$heatcall[f$heatcall > 100] <- 100
# Set non-heating times to zero
f$heatcall[f$status != 'on'] <- 0
# Calculate BTUs
f$btu[f$status == 'on'] <- (f$heatcall[f$status == 'on'] / 100 * 60000) * (f$tdiff[f$status == 'on'] / 60 / 60)

# Now aggregate to hour
f$hour <- format.Date(f$measurement_time, '%H')
# Sum by hour
sums <- tapply(f$btu, f$hour, sum, na.rm=T)
# Order it properly
curhour <- format.Date(Sys.time(), '%H')
sums.ordered <- sums[match(c(seq(as.numeric(curhour)+1,23),seq(00,curhour)), as.numeric(names(sums)))]

# Do some sunrise and sunset calculations
today <- Sys.Date()
yesterday <- today - 1
currenthour <- curhour #res$label[24]
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
title <- "Furnace BTUs in the Last Day"
label.x <- "Hour"
label.y <- "BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(sums.ordered, names.arg=names(sums.ordered), col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

