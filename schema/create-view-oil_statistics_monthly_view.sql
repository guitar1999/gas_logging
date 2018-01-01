CREATE OR REPLACE VIEW oil_statistics.oil_statistics_monthly_view AS (
    SELECT
        month,
        avg(runtime) FILTER (WHERE NOT DATE_PART('YEAR', CURRENT_TIMESTAMP) = year OR NOT DATE_PART('MONTH', CURRENT_TIMESTAMP) = month) AS runtime_avg,
        count(*) FILTER (WHERE NOT DATE_PART('YEAR', CURRENT_TIMESTAMP) = year OR NOT DATE_PART('MONTH', CURRENT_TIMESTAMP) = month) AS count
    FROM
        oil_statistics.oil_sums_monthly_view
    -- WHERE
    --     complete = 'yes'
    GROUP BY
        1
    ORDER BY
        1
);
