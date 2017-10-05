CREATE OR REPLACE VIEW oil_plotting.oil_daily_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY sum_date DESC),
            sum_date,
            SUM(runtime) AS runtime,
            'yes'::TEXT AS complete
        FROM
            oil_statistics.oil_sums_hourly_view
        GROUP BY
            sum_date
        ORDER BY
            sum_date DESC
        )
    SELECT
        u.sum_date,
        CONCAT_WS(' -', TO_CHAR(TO_TIMESTAMP(DATE_PART('month', u.sum_date)::text, 'MM'), 'Mon'), TO_CHAR(DATE_PART('day', u.sum_date), '09')) AS label,
        u.runtime,
        u1.runtime AS previous_year,
        u.complete,
        u.row_number
    FROM
        u
        LEFT JOIN u u1
            ON u.sum_date - INTERVAL '1 year' = u1.sum_date
    ORDER BY
        u.sum_date
);
