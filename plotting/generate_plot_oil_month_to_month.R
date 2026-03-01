if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
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

query <- paste("SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, hour, (sum_date || ' ' || hour || ':59:59')::timestamp with time zone AS timestamp, (make_date(2000, DATE_PART('month', sum_date)::integer, DATE_PART('day', sum_date)::integer) || ' ' || hour || ':59:59')::timestamp with time zone AS plotstamp, runtime, SUM(runtime) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('day', sum_date), hour) AS cumulative_runtime FROM oil_statistics.oil_sums_hourly_view WHERE DATE_PART('month', sum_date) = ", month, " ORDER BY DATE_PART('year', sum_date), DATE_PART('day', sum_date), hour;", sep="")
measurements <- dbGetQuery(con, query)
measurements$cumulative_runtime <- measurements$cumulative_runtime / 60

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)
pymin <- max(measurements$cumulative_runtime[measurements$timestamp == pxmin])

query <- paste("SELECT runtime_avg FROM oil_statistics.oil_statistics_monthly_view WHERE month = ", month, ";", sep="")
runtimeavg <- dbGetQuery(con, query) / 60
query <- paste("SELECT timestamp, (make_date(2000, DATE_PART('month', timestamp)::integer, DATE_PART('day', timestamp)::integer) || ' ' || to_char(timestamp, 'HH24:MI:SS'))::timestamp with time zone AS plotstamp, monthly_cum_avg_runtime FROM oil_plotting.oil_cumulative_averages WHERE DATE_PART('MONTH', timestamp) = ", month, " ORDER BY timestamp;", sep="")
cumruntimeavg <- dbGetQuery(con, query)
# query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
query <- "SELECT timestamp, (make_date(2000, DATE_PART('month', timestamp)::integer, DATE_PART('day', timestamp)::integer) || ' ' || to_char(timestamp, 'HH24:MI:SS'))::timestamp with time zone AS plotstamp, runtime FROM oil_plotting.cumulative_predicted_use_this_month_view ORDER BY timestamp;"
prediction <- dbGetQuery(con, query)
prediction$runtime <- prediction$runtime / 60
prediction <- rbind(measurements[dim(measurements)[1],c("timestamp", "plotstamp", "cumulative_runtime")], setNames(data.frame(prediction), c(names(measurements)[5], names(measurements)[6], names(measurements)[8])))

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 86400, 86400) - 3599

fname <- '/tmp/oil_month_to_month.png'
fname2 <- paste('oil_month_to_month_', month, '.png', sep='')
ymax <- max(c(measurements$cumulative_runtime, prediction$cumulative_runtime))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
# Set up empty plot
plot(measurements$plotstamp, measurements$cumulative_runtime, type='l', col='white', ylim=c(0,ymax), xlab='', ylab='Cumulative Runtime (Hours)')
abline(v=hseq, col='lightgrey', lty=3)
years <- seq(min(measurements$year), max(measurements$year))
ghostyears <- length(years) - 1
ghostlty <- rep(1, ghostyears)
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
lines(prediction$plotstamp, prediction$cumulative_runtime, col='blue4', lty=5)
# lines(predline, col='darkred', lty=2, lwd=1.5)
#abline(h=runtimeavg, col='orange')
lines(cumruntimeavg$plotstamp, cumruntimeavg$monthly_cum_avg_runtime / 60, col='orange')
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
leg.lty <- c(ghostlty, 1, 5, 1)
leg.col <- c(ghostcolor, 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

if (month == strftime(Sys.time(), format='%m')) {
  system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
}
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', fname2, sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)