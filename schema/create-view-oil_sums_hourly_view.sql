CREATE OR REPLACE VIEW oil_statistics.oil_sums_hourly_view AS (
    SELECT
        sum_date,
        hour,
        runtime
    FROM
        oil_statistics.oil_sums_hourly
    ORDER BY 1, 2
);
