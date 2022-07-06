if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

# Load the RData file with the model
#load('/home/jessebishop/scripts/gas_logging/data-furnace_model.RData')

# Get some data
#query <- "SELECT watts_ch3 AS watts, measurement_time, tdiff FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute') - (date_part('second', CURRENT_TIMESTAMP) * interval '1 second') ORDER BY measurement_time;"
query <- "SELECT *, (heatcall / 100. * 60000)::integer AS btuph FROM furnace_status((CURRENT_TIMESTAMP - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute') - (date_part('second', CURRENT_TIMESTAMP) * interval '1 second'))::timestamp, CURRENT_TIMESTAMP::timestamp);"
res <- dbGetQuery(con, query)


# Set a furnace status
#res$status[res$watts < 69] <- 'blower'
#res$status[res$watts < 40] <- 'off'
#res$status[res$tdiff > 3600] <- 'unknown'
#res$status[is.na(res$status)] <- 'on'
#res$status[res$watts > 500] <- 'dehumidification'

# Now predict on the data
#res$heatcall <- predict(m, res)

# Clean up bad values (a better training dataset will help here)
#res$heatcall[res$heatcall < 40] <- 40
#res$heatcall[res$heatcall > 100] <- 100

# Set non-heating records to zero
#res$heatcall[res$status != 'on'] <- 0

# Calculate BTUs
#res$btu[res$status == 'on'] <- (res$heatcall[res$status == 'on'] / 100 * 60000) * (res$tdiff[res$status == 'on'] / 60 / 60)
#res$btu[res$status != 'on'] <- 0
#res$btuph <- res$heatcall / 100 * 60000

fname <- '/tmp/ng_last_hours.png'

# Some help for plotting
mintime <- min(res$measurement_time)
maxtime <- max(res$measurement_time)
vseq <- seq(24000, 60000, 6000)
vlab <- c('24k', '30k', '36k', '42k', '48k', '54k', '60k')
hseq <- seq(mintime, mintime + 7200, 600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res2 <- dbGetQuery(con, query2)

# Plot!
png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$btuph, type='l', col='white', xlim=c(mintime, mintime + 7200), ylim=c(24000,60000), xlab='', ylab="Firing Rate (btu/hour)", main=paste("Natural Gas Usage since ", mintime), xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=mintime + 3600, col='black')
abline(h=vseq, col='grey', lty=2)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
lines(res$measurement_time, res$btuph, col='orange')
dev.off()

# Put on the web
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
