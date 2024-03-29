if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

# Get historic data
# query <- "WITH dates AS (SELECT generate_series::DATE AS d FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - CASE WHEN is_leapyear(DATE_PART('year', CURRENT_TIMESTAMP)::INTEGER) THEN interval '365 days' ELSE interval '364 days' END, '-1 day')), cur_btu AS (SELECT CURRENT_TIMESTAMP::DATE d, CURRENT_TIMESTAMP AS ts, btu + COALESCE((SELECT btu FROM boiler_summary(updated::timestamp, CURRENT_TIMESTAMP::timestamp)), 0) AS btu FROM oil.oil_usage_doy WHERE CASE WHEN is_leapyear(DATE_PART('year', CURRENT_TIMESTAMP)::INTEGER) THEN doy_leap ELSE doy_noleap END = DATE_PART('doy', CURRENT_TIMESTAMP)), up AS (UPDATE oil.oil_usage_doy AS oud SET (btu, updated) = (x.btu, x.ts) FROM cur_btu AS x WHERE oud.month=DATE_PART('month', x.ts) AND oud.day=DATE_PART('day', x.ts)) SELECT to_char(to_timestamp(DATE_PART('month', o.d)::text, 'MM'), 'Mon') || ' -' || to_char(DATE_PART('day', o.d), '09') AS label, CASE WHEN o.d = CURRENT_TIMESTAMP::DATE THEN cb.btu ELSE u.btu END AS btu, c1.btu AS btu_avg, u.complete AS complete FROM dates o INNER JOIN oil.oil_usage_doy u ON DATE_PART('doy', o.d)=CASE WHEN is_leapyear(DATE_PART('year', o.d)::INTEGER) THEN u.doy_leap ELSE u.doy_noleap END LEFT JOIN cur_btu cb ON cb.d=o.d LEFT JOIN oil_statistics.oil_sums_daily c1 ON c1.sum_date=o.d - interval '1 year' ORDER BY o.d;"
query <- "SELECT label, runtime AS btu, previous_year AS btu_avg, complete FROM oil_plotting.oil_daily_plot_view WHERE row_number < 366;"
res <- dbGetQuery(con, query)

res$jday <- res$label
today <- Sys.Date()
jday <- format(today, '%j')
year.this <- format(today, '%Y')
year.last <- as.numeric(year.this) - 1

# res$btu <- res$btu / 1000

fname <- '/tmp/ng_daily_1year.png'
title <- "Boiler Runtime in the Last Month"
label.x <- ""
label.y <- "Runtime (Minutes)"

png(filename=fname, width=10240, height=400, units='px', pointsize=12, bg='white')
#barplot(res$btu, names.arg=res$label, col='orange', las=2, main=title, ylab=label.y)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

