CREATE OR REPLACE VIEW oil_statistics.oil_sums_yearly_view AS (
    SELECT
        date_part('year', sum_date) AS year,
        sum(runtime) AS runtime --,
        -- CASE
        --     WHEN COUNT(*) / 24. > 364 THEN 'yes'
        --     ELSE 'no'
        -- END AS complete
    FROM
        oil_statistics.oil_sums_hourly
    GROUP BY
        1
    ORDER BY
        1
);
