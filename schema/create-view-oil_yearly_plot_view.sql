CREATE OR REPLACE VIEW oil_plotting.oil_yearly_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY DATE_PART('year', sum_date) DESC),
            DATE_PART('year', sum_date) AS year,
            SUM(runtime) AS runtime,
            'yes'::TEXT AS complete
        FROM
            oil_statistics.oil_sums_hourly_view
        GROUP BY
            DATE_PART('year', sum_date)
        ORDER BY
            DATE_PART('year', sum_date) DESC
        ),
    pytd AS (
        SELECT
            DATE_PART('year', CURRENT_DATE) AS year,
            SUM(runtime) +
                CASE
                    WHEN DATE_PART('year', CURRENT_DATE) - 1 = 2016 THEN 46048.72230754999999996671
                    ELSE 0
                END AS runtime
        FROM
            oil_statistics.oil_sums_hourly_view
        WHERE
            DATE_PART('year', sum_date) = DATE_PART('year', CURRENT_DATE) - 1
            AND sum_date <= CURRENT_DATE - INTERVAL '1 year'
         )
    SELECT
        u.year AS label,
        u.runtime,
        pytd.runtime AS previous_yeartodate_runtime,
        u.complete
    FROM
        u
        LEFT JOIN pytd
            ON u.year=pytd.year
    ORDER BY
        u.year
);
