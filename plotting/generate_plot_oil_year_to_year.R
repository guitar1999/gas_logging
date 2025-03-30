if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

query <- "SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, sum_date AS timestamp, (sum_date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', sum_date))::integer || ' year')::interval)::date AS plotstamp, runtime, SUM(runtime) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('doy', sum_date)) AS cumulative_runtime FROM oil_statistics.oil_sums_daily_view ORDER BY DATE_PART('year', sum_date), DATE_PART('doy', sum_date);"
measurements <- dbGetQuery(con, query)
measurements$cumulative_runtime <- measurements$cumulative_runtime / 60

xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)
pymin <- max(measurements$cumulative_runtime[measurements$timestamp == pxmin])

query <- "SELECT runtime_avg FROM oil_statistics.oil_statistics_monthly_view;"
runtimeavg <- dbGetQuery(con, query) / 60
query <- "SELECT timestamp::DATE AS timestamp, MAX(cum_avg_runtime) AS cum_avg_runtime FROM oil_plotting.oil_cumulative_averages GROUP BY timestamp::DATE ORDER BY timestamp::DATE;"
cumruntimeavg <- dbGetQuery(con, query)

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 1, 30)

fname <- '/tmp/oil_year_to_year.png'
ymax <- max(c(measurements$cumulative_runtime))

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
lines(cumruntimeavg$timestamp, cumruntimeavg$cum_avg_runtime / 60, col='orange')
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
leg.txt <- c(ghosttext, years[length(years)], "avg")
leg.lty <- c(ghostlty, 1, 1)
leg.col <- c(ghostcolor, 'red', 'orange')
legend("topleft", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
