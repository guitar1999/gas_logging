CREATE TABLE oil_statistics.oil_statistics_doy (
    doy_noleap integer CHECK (doy_noleap >=1 AND doy_noleap <= 365),
    doy_leap integer CHECK (doy_leap >= 1 AND doy_leap <= 366),
    month integer CHECK (month >= 1 AND month <= 12),
    day integer CHECK (day >=1 AND day <= 31),
    count integer,
    btu_avg numeric,
    previous_year numeric,
    current_year numeric,
    updated timestamp with time zone
);
\copy oil_statistics.oil_statistics_doy (doy_noleap, doy_leap, month, day) FROM 'doy_statistics.data'
UPDATE oil_statistics.oil_statistics_doy SET (count, btu_avg, previous_year, current_year, updated) = (0, 0, 0, 0, CURRENT_TIMESTAMP);
