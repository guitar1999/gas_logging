CREATE TABLE oil_statistics.oil_statistics_hourly_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    season text,
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);

INSERT INTO oil_statistics.oil_statistics_hourly_season (hour, season, count, btu_avg, updated) SELECT generate_series(0,23), 'winter', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_hourly_season (hour, season, count, btu_avg, updated) SELECT generate_series(0,23), 'spring', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_hourly_season (hour, season, count, btu_avg, updated) SELECT generate_series(0,23), 'summer', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_hourly_season (hour, season, count, btu_avg, updated) SELECT generate_series(0,23), 'fall', 0, 0, CURRENT_TIMESTAMP;

