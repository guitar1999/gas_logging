CREATE OR REPLACE VIEW oil_plotting.oil_monthly_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY MAX(sum_date) DESC),
            DATE_PART('month', sum_date) AS month,
            TO_CHAR(TO_TIMESTAMP(DATE_PART('month', sum_date)::text, 'MM'), 'Mon') AS month_text,
            SUM(runtime) AS runtime,
            'yes'::TEXT AS complete
        FROM
            oil_statistics.oil_sums_hourly_view
        GROUP BY
            DATE_PART('month', sum_date),
            DATE_PART('year', sum_date)
        ORDER BY
            MAX(sum_date) DESC
        LIMIT 12
        )
    SELECT
        u.month_text AS label,
        u.runtime,
        SUM(s.runtime_avg * s.count) / SUM(s.count) AS runtime_avg,
        u.complete
    FROM
        u
        INNER JOIN oil_statistics.oil_statistics_monthly_view s
            ON u.month=s.month
    GROUP BY
        u.month_text,
        u.runtime,
        u.complete,
        u.row_number
    ORDER BY
        u.row_number DESC
);
