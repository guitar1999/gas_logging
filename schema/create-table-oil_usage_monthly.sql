CREATE TABLE oil.oil_usage_monthly (
    month integer PRIMARY KEY CHECK (month > 0 AND month <= 12),
    btu numeric,
    btu_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
