CREATE VIEW oil_statistics.oil_statistics_monthly_view AS (
    SELECT
        month,
        avg(runtime) AS runtime_avg,
        count(*) AS count
    FROM
        oil_statistics.oil_sums_monthly_view
    -- WHERE
    --     complete = 'yes'
    GROUP BY
        1
    ORDER BY
        1
);
