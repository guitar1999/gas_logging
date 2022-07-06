if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

# Get historic data
# query <- "SELECT u.month AS label, u.btu,s.btu_avg, u.complete FROM oil_usage_monthly u INNER JOIN oil_statistics_monthly s ON u.month=s.month WHERE NOT u.month = date_part('month', CURRENT_TIMESTAMP) AND NOT u.updated IS NULL ORDER BY u.updated;"
query <- "SELECT label, runtime AS btu, runtime_avg AS btu_avg, complete FROM oil_plotting.oil_monthly_plot_view;"
res <- dbGetQuery(con, query)

# Get current data
# query <- "SELECT u.month AS label, u.btu, s.btu_avg, u.complete, u.updated FROM oil_usage_monthly u INNER JOIN oil_statistics_monthly s ON u.month=s.month WHERE u.month = date_part('month', CURRENT_TIMESTAMP);"
# res1 <- dbGetQuery(con,query)

# # Summarize the current BTUs
# query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
# res2 <- dbGetQuery(con,query)
# # Set to zero if NA
# res2$btu[is.na(res2$btu)] <- 0
# res1$btu <- res1$btu + res2$btu

# # Update the current month
# query <- paste("UPDATE oil_usage_monthly SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE month = ", res1$label, ";", sep='')
# dbGetQuery(con,query)

# res <- rbind(res, res1[1,1:4])
res$btu <- res$btu / 60
res$btu_avg <- res$btu_avg / 60

fname <- '/tmp/ng_monthly.png'
title <- "Boiler Runtime in the Last Year"
label.x <- "Month"
label.y <- "Runtime (Hours)"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
