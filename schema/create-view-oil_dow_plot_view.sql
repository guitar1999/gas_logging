CREATE OR REPLACE VIEW oil_plotting.oil_dow_plot_view AS (
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
        LIMIT 7
        )
    SELECT
        INITCAP(TO_CHAR(u.sum_date, 'day')) AS label,
        u.runtime,
        SUM(s.runtime_avg * s.count) / SUM(s.count) AS runtime_avg,
        u.complete
    FROM
        u
        INNER JOIN oil_statistics.oil_statistics_dow_view s
            ON DATE_PART('dow', u.sum_date)=s.dow
    GROUP BY
        u.sum_date,
        u.runtime,
        u.complete
    ORDER BY
        u.sum_date
);