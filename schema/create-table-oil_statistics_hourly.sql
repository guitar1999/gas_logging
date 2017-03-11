CREATE TABLE oil_statistics.oil_statistics_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);
INSERT INTO oil_statistics.oil_statistics_hourly (hour, count, btu_avg, updated) SELECT generate_series(0,23), 0, 0, CURRENT_TIMESTAMP;

