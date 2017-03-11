CREATE TABLE oil_statistics.oil_statistics_dow_season (
    dow integer CHECK (dow >= 0 AND dow <= 6),
    season text,
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);
INSERT INTO oil_statistics.oil_statistics_dow_season (dow, season, count, btu_avg, updated) SELECT generate_series(0,6), 'winter', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_dow_season (dow, season, count, btu_avg, updated) SELECT generate_series(0,6), 'spring', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_dow_season (dow, season, count, btu_avg, updated) SELECT generate_series(0,6), 'summer', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO oil_statistics.oil_statistics_dow_season (dow, season, count, btu_avg, updated) SELECT generate_series(0,6), 'fall', 0, 0, CURRENT_TIMESTAMP;

