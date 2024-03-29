if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

# query <- "SELECT u.day_of_week AS label, u.dow, u.btu, s.btu_avg, u.complete FROM oil.oil_usage_dow u INNER JOIN oil_statistics.oil_statistics_dow s ON u.dow=s.dow WHERE NOT u.dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY u.updated;"
query <- "SELECT label, runtime AS btu, runtime_avg AS btu_avg, complete FROM oil_plotting.oil_dow_plot_view;"
res <- dbGetQuery(con, query)

# Get current data
# query <- "SELECT u.day_of_week AS label, u.dow, u.btu, s.btu_avg, u.complete, u.updated FROM oil.oil_usage_dow u INNER JOIN oil_statistics.oil_statistics_dow s ON u.dow=s.dow WHERE u.dow = date_part('dow', CURRENT_TIMESTAMP);"
# res1 <- dbGetQuery(con,query)

# # Summarize the current BTUs
# query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
# res2 <- dbGetQuery(con,query)
# res2$btu[is.na(res2$btu)] <- 0
# res1$btu <- res1$btu + res2$btu

# Update the current hour
# query <- paste("UPDATE oil.oil_usage_dow SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE dow = ", res1$dow, ";", sep='')
# dbGetQuery(con,query)

# res <- rbind(res, res1[1,1:5])

# res$btu <- res$btu / 1000

fname <- '/tmp/ng_dow.png'
title <- "Boiler Runtime in the Last Week"
label.x <- "Day"
label.y <- "Runtime ("

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
