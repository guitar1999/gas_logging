CREATE VIEW oil_statistics.heating_degree_days_view AS (
    SELECT
        wm.doy,
        COALESCE(wf.hdd, ROUND(wm.hdd_avg, 0)::INTEGER) AS hdd
    FROM 
        weather_data.weather_avg_hdd_view wm 
        LEFT JOIN weather_data.weather_forecast wf ON wm.doy=DATE_PART('DOY', wf.forecast_date)
);
