CREATE TABLE oil_statistics.oil_statistics_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    count integer,
    btu_avg numeric,
    updated timestamp with time zone
);
INSERT INTO oil_statistics.oil_statistics_dow (dow, count, btu_avg, updated) SELECT generate_series(0,6), 0, 0, CURRENT_TIMESTAMP;
