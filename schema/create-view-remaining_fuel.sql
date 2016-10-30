CREATE OR REPLACE VIEW oil_statistics.remaining_fuel AS (
    WITH last_fill AS (
        SELECT
            DISTINCT ON (fill)
            delivery_date,
            gallons
        FROM
            oil.oil_deliveries
        WHERE 
            fill = true
        ORDER BY 
            fill,
            delivery_date
    ), subsequent_deliveries AS (
        SELECT
            COALESCE(SUM(od.gallons), 0) AS gallons
        FROM
            oil.oil_deliveries od,
            last_fill lf
        WHERE 
            od.delivery_date > lf.delivery_date
    ), usage AS (
        SELECT
            SUM(bds.gallon) AS gallons_used
        FROM
            oil_statistics.boiler_daily_statistics bds,
            last_fill lf
        WHERE
            bds.date > lf.delivery_date
    ), average_usage AS (
        SELECT 
            AVG(gallon) AS avg_gal
        FROM
            oil_statistics.boiler_daily_statistics
        WHERE 
            date > CURRENT_TIMESTAMP::DATE - interval '7 days'
    ), remaining_fuel AS (
        SELECT 
            (275.0 + sd.gallons) - u.gallons_used AS remaining_gallons
        FROM
            subsequent_deliveries sd,
            usage u
    )
    SELECT
        rf.remaining_gallons,
        ROUND(rf.remaining_gallons / 275 * 100, 2) AS tank_level,
        ROUND(rf.remaining_gallons / au.avg_gal, 1) AS remaining_days
    FROM
        remaining_fuel rf,
        average_usage au
);