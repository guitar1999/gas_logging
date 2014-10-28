if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

# Load the RData file with the model
load('/home/jessebishop/scripts/gas_logging/data-furnace_model.RData')

# Get some data
query <- "SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute') - (date_part('second', CURRENT_TIMESTAMP) * interval '1 second') ORDER BY measurement_time;"
res <- dbGetQuery(con, query)


# Set a furnace status
res$status[res$watts < 69] <- 'blower'
res$status[res$watts < 40] <- 'off'
res$status[res$tdiff > 3600] <- 'unknown'
res$status[is.na(res$status)] <- 'on'
res$status[res$watts > 500] <- 'dehumidification'

# Now predict on the data
res$heatcall <- predict(m, res)

# Clean up bad values (a better training dataset will help here)
res$heatcall[res$heatcall < 40] <- 40
res$heatcall[res$heatcall > 100] <- 100

# Set non-heating records to zero
res$heatcall[res$status != 'on'] <- 0

# Calculate BTUs
res$btu[res$status == 'on'] <- (res$heatcall[res$status == 'on'] / 100 * 60000) * (res$tdiff[res$status == 'on'] / 60 / 60)
res$btu[res$status != 'on'] <- 0
res$btuph <- res$heatcall / 100 * 60000

fname <- '/var/www/electricity/ng_last_hours.png'
mintime <- min(res$measurement_time)
maxtime <- max(res$measurement_time)
#maxwatts <- max(res$watts)
#if (maxwatts - min(res$watts) < 3000) {
#    vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
#    vlab <- vseq
#    ymin <- 0
#} else {
#    vseq <- log10(c(1,10,50,100,250,500,750,1000,2500,5000,7500,10000))
#    vlab <- 10^vseq
#    maxwatts <- log10(maxwatts)
#    res$watts <- log10(res$watts)
#    res$watts_ch3 <- log10(res$watts_ch3)
#    ymin <- min(c(min(res$watts),min(res$watts_ch3, na.rm = TRUE)))
#}

hseq <- seq(mintime, mintime + 7200, 600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$btuph, type='l', col='white', xlim=c(mintime, mintime + 7200), xlab="Time", ylab="Firing Rate (btu/hour)", main=paste("Natural Gas Usage since ", mintime), xaxt='n')#, yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
#axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=mintime + 3600, col='black')
#abline(h=vseq, col='grey', lty=2)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
lines(res$measurement_time, res$btuph, col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
