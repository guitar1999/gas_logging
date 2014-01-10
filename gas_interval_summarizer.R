if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

# Load the RData file with the model
load('/home/jessebishop/scripts/gas_logging/data-furnace_model.RData')

# Get the argument(s) if running from commandline
if (exists('updatequery') == FALSE){
    args <- commandArgs(trailingOnly=TRUE)
    query <- toString(args[1])
}

# Run the query
f <- dbGetQuery(con, query)

# Set a furnace status
f$status[f$watts < 60] <- 'blower'
f$status[f$watts < 40] <- 'off'
f$status[f$tdiff > 600] <- 'unknown'
f$status[is.na(f$status)] <- 'on'
f$status[f$watts > 500] <- 'dehumidification'

# Set watts = 0 where watts is NA
f$watts[is.na(f$watts) == TRUE] <- 0

# Now predict on the data
f$heatcall <- predict(m, f)

# Clean up bad values (a better training dataset will help here)
f$heatcall[f$heatcall < 40] <- 40
f$heatcall[f$heatcall > 100] <- 100

# Set non-heating records to zero
f$heatcall[f$status != 'on'] <- 0

# Calculate BTUs
f$btu[f$status == 'on'] <- (f$heatcall[f$status == 'on'] / 100 * 60000) * (f$tdiff[f$status == 'on'] / 60 / 60)

# Sum the BTUs
btu <- sum(f$btu, na.rm=TRUE)
print(btu)
