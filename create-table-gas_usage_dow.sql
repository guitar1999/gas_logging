CREATE TABLE gas_usage_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    day_of_week text,
    btu numeric,
    btu_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    timestamp timestamp with time zone
);
