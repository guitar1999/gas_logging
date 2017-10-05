CREATE OR REPLACE VIEW oil_statistics.oil_sums_monthly_view AS (
    SELECT
        date_part('year', sum_date) AS year,
        date_part('month', sum_date) AS month,
        sum(runtime) AS runtime --,
        -- CASE
        --     WHEN
        --         CASE
        --             WHEN DATE_PART('month', sum_date) = 3 THEN COUNT(*) + 1
        --             WHEN DATE_PART('month', sum_date) = 11 THEN COUNT(*) - 1
        --             ELSE COUNT(*)
        --         END / 24. = num_days(date_part('year', sum_date)::INTEGER, date_part('month', sum_date)::INTEGER) THEN 'yes'
        --     ELSE 'no'
        -- END AS complete
    FROM
        oil_statistics.oil_sums_hourly
    GROUP BY
        1, 2
    ORDER BY
        1, 2
);
