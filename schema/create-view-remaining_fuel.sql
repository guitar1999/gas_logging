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
            delivery_date DESC
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
            COALESCE(ROUND(SUM(runtime / 60 * 0.666205227383988), 2), 0) AS gallons_used
        FROM
            oil_statistics.oil_sums_hourly_view,
            last_fill lf
        WHERE
            sum_date >= lf.delivery_date
    ), remaining_fuel AS (
        SELECT 
            (260.0 + sd.gallons) - u.gallons_used AS remaining_gallons
        FROM
            subsequent_deliveries sd,
            usage u
    ), fuel_consumption AS (
        SELECT 
            date,
            predicted_runtime / 60 * 0.666205227383988 AS gallons,
            remaining_gallons - SUM(predicted_runtime / 60 * 0.666205227383988) OVER (ORDER BY date) as remaining_gallons
        FROM 
            oil_statistics.boiler_predicted_runtime_1_year_view,
            remaining_fuel
    ), fuel_warning AS (
        SELECT
            MAX(date) AS low_date
        FROM 
            fuel_consumption
        WHERE 
            remaining_gallons < (0.25 * 260) = false
    ), fuel_empty AS (
        SELECT
            MAX(date) AS empty_date
        FROM 
            fuel_consumption
        WHERE 
            remaining_gallons < 0 = false
    )
    SELECT
        rf.remaining_gallons,
        ROUND(rf.remaining_gallons / 260 * 100, 2) AS tank_level,
        low_date,
        low_date - CURRENT_DATE AS low_days,
        empty_date,
        empty_date - CURRENT_DATE AS empty_days
    FROM
        remaining_fuel rf,
        fuel_warning,
        fuel_empty
);
