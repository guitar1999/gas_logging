if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

# Get historic data
#query <- "SELECT u.doy AS label, u.btu, btu_avg, u.complete FROM oil.oil_usage_doy u INNER JOIN oil_statistics.oil_statistics_doy s ON u.doy=s.doy WHERE u.updated >= CURRENT_TIMESTAMP - interval '29 days' AND NOT u.updated IS NULL AND NOT doy = date_part('doy', CURRENT_TIMESTAMP) ORDER BY u.updated;"
query <- "WITH dates AS (SELECT generate_series::DATE AS d FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - interval '30 days', '-1 day')), cur_btu AS (SELECT CURRENT_TIMESTAMP::DATE d, CURRENT_TIMESTAMP AS ts, btu + COALESCE((SELECT btu FROM boiler_summary(updated::timestamp, CURRENT_TIMESTAMP::timestamp)), 0) AS btu FROM oil.oil_usage_doy WHERE CASE WHEN is_leapyear(DATE_PART('year', CURRENT_TIMESTAMP)::INTEGER) THEN doy_leap ELSE doy_noleap END = DATE_PART('doy', CURRENT_TIMESTAMP)), up AS (UPDATE oil.oil_usage_doy AS oud SET (btu, updated) = (x.btu, x.ts) FROM cur_btu AS x WHERE oud.month=DATE_PART('month', x.ts) AND oud.day=DATE_PART('day', x.ts)) SELECT to_char(to_timestamp(DATE_PART('month', o.d)::text, 'MM'), 'Mon') || ' -' || to_char(DATE_PART('day', o.d), '09') AS label, CASE WHEN o.d = CURRENT_TIMESTAMP::DATE THEN cb.btu ELSE u.btu END AS btu, c1.btu AS btu_avg, u.complete AS complete FROM dates o INNER JOIN oil.oil_usage_doy u ON DATE_PART('doy', o.d)=CASE WHEN is_leapyear(DATE_PART('year', o.d)::INTEGER) THEN u.doy_leap ELSE u.doy_noleap END LEFT JOIN cur_btu cb ON cb.d=o.d LEFT JOIN oil_statistics.oil_sums_daily c1 ON c1.sum_date=o.d - interval '1 year' ORDER BY o.d;"
res <- dbGetQuery(con, query)

# Get current data
# query <- "SELECT u.doy AS label, u.btu, btu_avg, u.complete, u.updated FROM oil.oil_usage_doy u INNER JOIN oil_statistics.oil_statistics_doy s ON u.doy=s.doy WHERE doy = date_part('doy', CURRENT_TIMESTAMP);"
# res1 <- dbGetQuery(con,query)


# Summarize the current BTUs
# query <- paste("SELECT * FROM get_oil_usage('", res1$timestamp, "', CURRENT_TIMESTAMP::timestamp);", sep='')
# btu <- source('/home/jessebishop/scripts/oil_logging/oil_interval_summarizer.R')$value
# res1$btu <- res1$btu + btu

# Update the current doy
# query <- paste("UPDATE oil.oil_usage_doy SET (btu, timestamp) = (", res1$btu, ", CURRENT_TIMESTAMP) WHERE doy = ", res1$label, ";", sep='')
# dbGetQuery(con,query)

# res <- rbind(res, res1[1,1:4])
res$jday <- res$label
today <- Sys.Date()
jday <- format(today, '%j')
year.this <- format(today, '%Y')
year.last <- as.numeric(year.this) - 1
#res$label <- format(as.Date(res$label - 1, origin=paste(ifelse(res$label <= jday, year.this, year.last), '-01-01', sep='')), '%b-%d')

res$btu <- res$btu / 1000

fname <- '/var/www/electricity/ng_daily.png'
title <- "Boiler BTUs in the Last Month"
#label.x <- "Hour"
label.y <- "Thousand BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=2, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

