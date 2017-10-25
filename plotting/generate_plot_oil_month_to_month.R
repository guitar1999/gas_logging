if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

# Parse args in case we want to run another month
args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
  # We want to run the current month
  month <- strftime(Sys.time(), format='%m')
} else {
  # We want to run a specific month
  month <- args[1]
}

query <- paste("SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, hour, (sum_date || ' ' || hour || ':59:59')::timestamp AS timestamp, ((sum_date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', sum_date))::integer || ' year')::interval)::date || ' ' || hour || ':59:59')::timestamp AS plotstamp, runtime, SUM(runtime) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('day', sum_date), hour) AS cumulative_runtime FROM oil_statistics.oil_sums_hourly_view WHERE DATE_PART('month', sum_date) = ", month, " ORDER BY DATE_PART('year', sum_date), DATE_PART('day', sum_date), hour;", sep="")
measurements <- dbGetQuery(con, query)

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)


query <- paste("SELECT runtime_avg FROM oil_statistics.oil_statistics_monthly_view WHERE month = ", month, ";", sep="")
runtimeavg <- dbGetQuery(con, query)

# query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
query <- "WITH today AS (select sum_date, runtime from oil_statistics.oil_sums_daily_view WHERE sum_date = CURRENT_DATE), cumulative_sum AS (SELECT date, predicted_runtime, sum(predicted_runtime) OVER (ORDER BY date) FROM oil_statistics.boiler_predicted_runtime_1_year_view WHERE date < DATE_TRUNC('MONTH', CURRENT_DATE + INTERVAL '1 MONTH')) SELECT (date || ' 23:59:59')::TIMESTAMP, sum - t.runtime + m.runtime AS runtime FROM cumulative_sum, today t, (SELECT runtime FROM oil_statistics.oil_sums_monthly_view WHERE DATE_PART('YEAR', CURRENT_DATE) = year AND DATE_PART('MONTH', CURRENT_DATE) = month) AS m;"
prediction <- dbGetQuery(con, query)
# prediction <- rbind(prediction, setNames(data.frame(xmax, prediction$minute[length(prediction$minute)]), names(prediction)))
# predline <- rbind(measurements[dim(measurements)[1],c("timestamp", "cumulative_runtime")], setNames(data.frame(prediction[dim(prediction)[1],]), c(names(measurements)[5], names(measurements)[8])))

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 86400, 86400) - 3599

fname <- '/var/www/electricity/oil_month_to_month.png'
fname2 <- paste('oil_month_to_month_', month, '.png', sep='')
ymax <- max(c(measurements$cumulative_runtime, prediction$runtime))

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
lines(prediction$timestamp, prediction$runtime, col='blue4', lty=2)
# lines(predline, col='darkred', lty=2, lwd=1.5)
#abline(h=runtimeavg, col='orange')
if (ghostyears == 0) {
  ghosttext <- ''
  ghostcolor <- 'white'
} else if (ghostyears == 1) {
  ghosttext <- years[1]
  ghostcolor <- c(ghostcolors[1])
} else if (ghostyears == 2) {
  ghosttext <- c(years[1], years[2])
  ghostcolor <- c(ghostcolors[1], ghostcolors[ghostyears])
} else {
  ghosttext <- c(years[1], '. . . ', years[ghostyears])
  ghostcolor <- c(ghostcolors[1], 'white', ghostcolors[ghostyears])
}
leg.txt <- c(ghosttext, years[length(years)], "predicted total runtime", "average runtime")
leg.lty <- c(1, 1, 1, 1, 2, 1)
leg.col <- c(ghostcolor, 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

if (month == strftime(Sys.time(), format='%m')) {
  system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
}
system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", fname2, sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

