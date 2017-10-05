CREATE OR REPLACE VIEW oil_statistics.oil_sums_daily_view AS (
    SELECT
        sum_date,
        date_part('dow', sum_date) AS dow,
        sum(runtime) AS runtime
    FROM
        oil_statistics.oil_sums_hourly
    GROUP BY
        1, 2
    ORDER BY
        1
);
