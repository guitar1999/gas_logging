CREATE TABLE oil.oil_usage_doy (
    doy_noleap integer CHECK (doy_noleap >=1 AND doy_noleap <= 365),
    doy_leap integer CHECK (doy_leap >= 1 AND doy_leap <= 366),
    month integer CHECK (month >= 1 AND month <= 12),
    day integer CHECK (day >=1 AND day <= 31),
    btu numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone

);
\copy oil.oil_usage_doy (doy_noleap, doy_leap, month, day) FROM data/doy_statistics.data
UPDATE oil.oil_usage_doy SET (btu, complete, updated) = (0, 'no', CURRENT_TIMESTAMP);