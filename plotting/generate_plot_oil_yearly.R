if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

# Get historic data
# query <- "SELECT year AS label, btu, complete FROM oil_usage_yearly WHERE NOT year = date_part('year', CURRENT_TIMESTAMP) AND NOT updated IS NULL ORDER BY updated;"
query <- "SELECT label, runtime AS btu, previous_yeartodate_runtime AS btu_avg, complete FROM oil_plotting.oil_yearly_plot_view;"
res <- dbGetQuery(con, query)

# Get current data
# query <- "SELECT year AS label, btu, complete, updated FROM oil_usage_yearly WHERE year = date_part('year', CURRENT_TIMESTAMP);"
# res1 <- dbGetQuery(con,query)

# # Summarize the current BTUs
# query <- paste("SELECT btu, CURRENT_TIMESTAMP AS updated FROM boiler_summary('", res1$updated, "', CURRENT_TIMESTAMP::timestamp);", sep='')
# res2 <- dbGetQuery(con,query)
# # Set to zero if NA
# res2$btu[is.na(res2$btu)] <- 0
# res1$btu <- res1$btu + res2$btu

# # Update the current year
# query <- paste("UPDATE oil_usage_yearly SET (btu, updated) = (", res1$btu, ",'", res2$updated, "') WHERE year = ", res1$label, ";", sep='')
# dbGetQuery(con,query)

# res <- rbind(res, res1[1,1:3])

res$btu <- res$btu / 60
res$btu_avg <- res$btu_avg / 60

fname <- '/tmp/ng_yearly.png'
title <- "Boiler Runtime By Year"
label.x <- "Year"
label.y <- "Runtime (Hours)"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#b <- barplot(res$btu, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
#points(b, res$btu_avg / 60)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

