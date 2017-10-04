CREATE TABLE oil_statistics.oil_sums_hourly (
    sum_date DATE NOT NULL,
    hour INTEGER NOT NULL,
    runtime NUMERIC NOT NULL,
    btu NUMERIC NOT NULL,
    PRIMARY KEY (sum_date, hour)
);
