CREATE TABLE oil.oil_usage_doy (
    doy integer PRIMARY KEY CHECK (doy > 0 AND doy <= 366),
    btu numeric,
    btu_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
