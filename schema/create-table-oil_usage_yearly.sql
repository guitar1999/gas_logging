CREATE TABLE oil.oil_usage_yearly (
    year integer PRIMARY KEY,
    btu numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
