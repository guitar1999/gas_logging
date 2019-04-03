CREATE OR REPLACE VIEW oil_statistics.oil_statistics_hourly_view AS (
    SELECT
        date_part('dow', sum_date) AS dow,
        m.season,
        hour,
        avg(runtime) AS runtime_avg,
        count(*) AS count
    FROM
        oil_statistics.oil_sums_hourly_view e INNER JOIN
        weather_data.heating_season m ON date_part('MONTH', e.sum_date)=m.month
    GROUP BY
        1, 2, 3
    ORDER BY
        2, 1, 3
);
