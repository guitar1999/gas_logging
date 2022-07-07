if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}
source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))

statusquery <- "SELECT status FROM furnace_status ORDER BY status_time DESC LIMIT 1;"
status <- dbGetQuery(con, statusquery)

# Load the RData file with the model
load(paste(githome, '/gas_logging/data-furnace_model.RData', sep=''))

# Get the argument(s) if running from commandline
if (exists('updatequery') == FALSE){
    args <- commandArgs(trailingOnly=TRUE)
    query <- toString(args[1])
}

# Run the query
f <- dbGetQuery(con, query)

# A hack until we put get_gas_usage in hourly, dow, and doy!
if (! "get_gas_usage" %in% query){
#    f$status <- "OFF"
}

# Set a furnace status
f$status[f$watts < 69 & f$status == "ON"] <- 'blower'
f$status[f$watts < 40 & f$status == "ON"] <- 'off'
f$status[f$tdiff > 600 & f$status == "ON"] <- 'unknown'
#f$status[is.na(f$status)] <- 'on'
f$status[f$watts > 500 & f$status == "ON"] <- 'dehumidification'

# Set watts = 0 where watts is NA
f$watts[is.na(f$watts) == TRUE] <- 0

# Now predict on the data
f$heatcall <- predict(m, f)

# Clean up bad values (a better training dataset will help here)
f$heatcall[f$heatcall < 40] <- 40
f$heatcall[f$heatcall > 100] <- 100

# Set non-heating records to zero
f$heatcall[f$status != 'ON'] <- 0

# Calculate BTUs
f$btu[f$status == 'ON'] <- (f$heatcall[f$status == 'ON'] / 100 * 60000) * (f$tdiff[f$status == 'ON'] / 60 / 60)

# Sum the BTUs
btu <- sum(f$btu, na.rm=TRUE)
print(btu)
