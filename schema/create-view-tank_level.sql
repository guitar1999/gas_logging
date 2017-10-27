CREATE OR REPLACE VIEW oil.tank_level AS (
    WITH data_range AS (
        SELECT 
            *
        FROM
            generate_series(
                (SELECT 
                    MIN(delivery_date) - INTERVAL '1 HOUR'
                FROM
                    oil.oil_deliveries
                ), 
                CURRENT_TIMESTAMP,
                '1 hour'::INTERVAL) AS timestamp
        ), running_tally AS (
        SELECT
            d.timestamp,
            COALESCE(od.gallons, COALESCE(iv.initial_value, 0)) AS additions,
            COALESCE(oshv.runtime / 60 * 0.666205227383988, 0) AS usage
        FROM
            data_range d
            LEFT JOIN (
                SELECT
                    MIN(d.timestamp) AS timestamp,
                    31.5 AS initial_value
                FROM data_range d
                ) AS iv ON d.timestamp=iv.timestamp
            LEFT JOIN oil.oil_deliveries od ON d.timestamp = od.delivery_date
            LEFT JOIN oil_statistics.oil_sums_hourly_view oshv ON d.timestamp::DATE=oshv.sum_date AND DATE_PART('HOUR', d.timestamp)=oshv.hour
        )
    SELECT
        rt.timestamp,
        SUM(rt.additions - rt.usage) OVER (ORDER BY rt.timestamp) AS tank_level
    FROM
        running_tally rt
);
