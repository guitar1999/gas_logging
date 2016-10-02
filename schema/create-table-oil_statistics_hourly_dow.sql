CREATE TABLE oil_statistics.oil_statistics_hourly_dow (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);
\copy oil_statistics.oil_statistics_hourly_dow (hour, dow) FROM data/hourly_dow_statistics.data
UPDATE oil_statistics.oil_statistics_hourly_dow SET (count, btu_avg, updated) = (0, 0, CURRENT_TIMESTAMP);

