CREATE TABLE gas_usage_yearly (
    year integer PRIMARY KEY,
    btu numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    timestamp timestamp with time zone
);
