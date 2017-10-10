CREATE OR REPLACE VIEW oil_statistics.oil_sums_hourly_view AS (
    SELECT
        sum_date,
        hour,
        runtime
    FROM
        (SELECT
            sum_date,
            hour,
            runtime
        FROM
            oil_statistics.oil_sums_hourly
        UNION
        SELECT
            CURRENT_TIMESTAMP::DATE AS sum_date,
            DATE_PART('HOUR', CURRENT_TIMESTAMP)::INTEGER AS hour,
            total_boiler_runtime AS runtime
        FROM
            boiler_summary(DATE_TRUNC('HOUR', CURRENT_TIMESTAMP)::TIMESTAMP, CURRENT_TIMESTAMP::TIMESTAMP)
        ) AS x
    ORDER BY 1, 2
);
