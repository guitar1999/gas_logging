if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT year AS label, btu, complete FROM gas_usage_yearly WHERE NOT year = date_part('year', CURRENT_TIMESTAMP) AND NOT timestamp IS NULL ORDER BY timestamp;"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/ng_yearly.png'
title <- "Electricity Usage By Year"
label.x <- "Year"
label.y <- "btu"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$btu, names.arg=res$label, col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

