CREATE TABLE oil_statistics.oil_statistics_monthly (
    month integer PRIMARY KEY CHECK (month >= 1 AND month <= 12),
    count integer,
    btu_avg numeric,
    previous_year numeric,
    updated timestamp with time zone
);
INSERT INTO oil_statistics.oil_statistics_monthly SELECT generate_series(1,12), 0, 0, 0, CURRENT_TIMESTAMP;
