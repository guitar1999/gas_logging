CREATE TABLE oil_statistics.oil_sums_monthly (
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    btu NUMERIC NOT NULL,
    PRIMARY KEY (year, month)
);
