CREATE TABLE oil.oil_usage_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    btu numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
INSERT INTO oil.oil_usage_hourly (hour, btu, complete, updated) SELECT generate_series(0,23), 0, 'no', CURRENT_TIMESTAMP;
