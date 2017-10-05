CREATE OR REPLACE VIEW oil_statistics.oil_statistics_dow_view AS (
    SELECT
        date_part('dow', sum_date) AS dow,
        m.season,
        avg(runtime) AS runtime_avg,
        count(*) AS count
    FROM
        oil_statistics.oil_sums_daily_view e INNER JOIN
        weather_data.meteorological_season m ON date_part('doy', e.sum_date)=m.doy
    GROUP BY
        1, 2
    ORDER BY
        2, 1
);