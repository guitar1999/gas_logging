# Training Data
df <- read.csv('Downloads/Furnace - heat.csv')
# Real Data
f <- read.csv('Downloads/furnace.csv')
f$timestamp <- as.POSIXct(f$timestamp)

# Outlier removal
df <- subset(df, df$furnaceheat != 0)
df <- subset(df, df$airflow != 0)
df <- subset(df, df$inducer != 0) 

# Plot
plot(df$watts, df$furnaceheat, type='p', col='blue', pch=19)
plot(df$watts,log10(df$furnaceheat), type='p', col='red', pch=3)
plot(log10(df$watts),log10(df$furnaceheat), type='p', col='red', pch=3)
plot(log10(df$watts),df$furnaceheat, type='p', col='red', pch=3)


# Vector of watts to test on
h <- seq(0,400)

# Model
#runmod <- function(porder){
porder <- 5
m <- lm(furnaceheat ~ poly(watts, porder), data=df)
p <- predict(m)
plot(df$watts, df$furnaceheat, type='p', col='blue', pch=19)
points(df$watts,p,col='red', pch=3)
np <- predict(m,data.frame(watts=h))
points(h,np,col='green', pch=8)
#}

# Set a furnace status
f$status[f$watts < 60] <- 'blower'
f$status[f$watts < 40] <- 'off'
f$status[is.na(f$status)] <- 'on'
f$status[f$watts > 500] <- 'dehumidification'
# Now predict on the data
f$heatcall <- predict(m, f)
# Clean up bad values (a better training dataset will help here)
f$heatcall[f$heatcall < 40] <- 40
f$heatcall[f$heatcall > 100] <- 100
# Set non-heating times to zero
f$heatcall[f$status != 'on'] <- 0
# Calculate BTUs
f$btu[f$status == 'on'] <- (f$heatcall[f$status == 'on'] / 100 * 60000) * (f$tdiff[f$status == 'on'] / 60 / 60)





