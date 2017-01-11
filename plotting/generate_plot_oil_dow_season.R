if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "WITH dates AS (SELECT generate_series::DATE AS d FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - interval '6 days', '-1 day')) SELECT u.day_of_week AS label, u.dow, u.btu, s.btu_avg, u.complete FROM dates o INNER JOIN oil.oil_usage_dow u ON DATE_PART('dow', o.d)=u.dow INNER JOIN weather_data.meteorological_season m ON DATE_PART('doy', o.d)=m.doy LEFT JOIN oil_statistics.oil_statistics_dow_season s ON u.dow=s.dow AND m.season=s.season ORDER BY o.d;"
res <- dbGetQuery(con, query)

res$btu <- res$btu / 1000
res$btu_avg <- res$btu_avg / 1000

fname <- '/var/www/electricity/ng_dow_season.png'
title <- "Boiler BTUs Used in the Last Week"
label.x <- "Day"
label.y <- "Thousand BTU"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
