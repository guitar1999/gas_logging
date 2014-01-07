CREATE TABLE gas_usage_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    btu numeric,
    btu_avg numeric,
    btu_avg_dow numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    timestamp timestamp with time zone
);
