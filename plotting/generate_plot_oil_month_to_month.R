if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

query <- "SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, hour, (sum_date || ' ' || hour || ':59:59')::timestamp AS timestamp, ((sum_date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', sum_date))::integer || ' year')::interval)::date || ' ' || hour || ':59:59')::timestamp AS plotstamp, runtime, SUM(runtime) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('day', sum_date), hour) AS cumulative_runtime FROM oil_statistics.oil_sums_hourly_view WHERE DATE_PART('month', sum_date) = DATE_PART('month', CURRENT_TIMESTAMP) ORDER BY DATE_PART('year', sum_date), DATE_PART('day', sum_date), hour;"
measurements <- dbGetQuery(con, query)

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)


query <- "SELECT runtime_avg FROM oil_statistics.oil_statistics_monthly_view WHERE month = date_part('month', CURRENT_TIMESTAMP);"
runtimeavg <- dbGetQuery(con, query)

# query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
# prediction <- dbGetQuery(con, query)
# prediction <- rbind(prediction, setNames(data.frame(xmax, prediction$minute[length(prediction$minute)]), names(prediction)))
# predline <- rbind(measurements[dim(measurements)[1],c("timestamp", "cumulative_runtime")], setNames(data.frame(prediction[dim(prediction)[1],]), c(names(measurements)[5], names(measurements)[8])))

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 86400, 86400) - 3599

fname <- '/var/www/electricity/oil_month_to_month.png'
fname2 <- paste('month_to_month_', strftime(Sys.time(), format='%b'), '.png', sep='')
ymax <- max(c(measurements$cumulative_runtime))#, prediction$minute))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
# Set up empty plot
plot(measurements$plotstamp, measurements$cumulative_runtime, type='l', col='white', ylim=c(0,ymax), xlab='', ylab='Cumulative runtime')
abline(v=hseq, col='lightgrey', lty=2)
years <- seq(min(measurements$year), max(measurements$year))
ghostyears <- length(years) - 1
ghostcolors <- grey.colors(ghostyears,start=0.8, end=0.5)
for (i in seq(1, length(years))){
    plotdata <- subset(measurements, measurements$year == years[i])
    if (years[i] < max(years)) {
        linecolor <- ghostcolors[i]
    } else {
        linecolor <- 'red'
    }
    lines(plotdata$plotstamp, plotdata$cumulative_runtime, col=linecolor, lwd=1.5)
}
# lines(prediction$time, prediction$minute, col='blue4', lty=2)
# lines(predline, col='darkred', lty=2, lwd=1.5)
#abline(h=runtimeavg, col='orange')
leg.txt <- c(years[1], '. . .', years[ghostyears], years[length(years)], "predicted total runtime", "average runtime")
leg.lty <- c(1, 1, 1, 1, 2, 1)
leg.col <- c(ghostcolors[1], 'white', ghostcolors[ghostyears], 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", fname2, sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

