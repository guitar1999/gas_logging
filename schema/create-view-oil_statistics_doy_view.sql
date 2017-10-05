CREATE OR REPLACE VIEW oil_statistics.oil_statistics_doy_view AS (
    SELECT
        date_part('month', sum_date) AS month,
        date_part('day', sum_date) AS day,
        avg(runtime) AS runtime_avg,
        count(*) AS count
    FROM
        oil_statistics.oil_sums_daily_view
    GROUP BY
        1, 2
    ORDER BY
        1, 2
);