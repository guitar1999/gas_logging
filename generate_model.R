# Training Data
df <- read.csv('/home/jessebishop/scripts/gas_logging/data-furnace_model.csv')

# Outlier removal
df <- subset(df, df$furnaceheat != 0)
df <- subset(df, df$airflow != 0)
df <- subset(df, df$inducer != 0) 

# Build a model (5th order polynomial seems to work best for now)
porder <- 5
m <- lm(furnaceheat ~ poly(watts, porder), data=df)

save(m,porder,file='/home/jessebishop/scripts/gas_logging/data-furnace_model.RData')
