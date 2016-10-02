CREATE TABLE oil_statistics.oil_statistics_hourly_dow_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    season text,
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);
\copy oil_statistics.oil_statistics_hourly_dow_season (hour, dow, season) FROM data/hourly_dow_season_statistics.data
UPDATE oil_statistics.oil_statistics_hourly_dow_season SET (count, btu_avg, updated) = (0, 0, CURRENT_TIMESTAMP);
