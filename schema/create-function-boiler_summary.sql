CREATE OR REPLACE FUNCTION boiler_summary(start_date timestamp, end_date timestamp) 
RETURNS TABLE(btu numeric, gallons numeric, kwh numeric, boiler_cycles integer, total_boiler_runtime numeric, avg_boiler_runtime numeric, min_boiler_runtime numeric, max_boiler_runtime numeric)
AS $$
BEGIN
    RETURN QUERY WITH cycles AS (
        SELECT 
            b.event_group, 
            b.system_status, 
            SUM(b.tdiff) / 60 AS runtime, 
            SUM(b.btu) AS btu, 
            SUM(b.gallons) AS gallons,
            SUM(b.watts * b.tdiff / 1000 / 60 / 60) AS kwh 
        FROM 
            boiler_status(start_date, end_date) b
        GROUP BY 
            event_group, 
            system_status 
        ORDER BY 
            event_group,
            system_status
        ) SELECT
            SUM(CASE WHEN cycles.system_status = 'boiler' THEN cycles.btu END),
            SUM(CASE WHEN cycles.system_status = 'boiler' THEN cycles.gallons END),
            SUM(cycles.kwh),
            COUNT(CASE WHEN cycles.system_status = 'boiler' THEN cycles.* END)::INTEGER,
            SUM(CASE WHEN cycles.system_status = 'boiler' THEN cycles.runtime END),
            AVG(CASE WHEN cycles.system_status = 'boiler' THEN cycles.runtime END),
            MIN(CASE WHEN cycles.system_status = 'boiler' THEN cycles.runtime END),
            MAX(CASE WHEN cycles.system_status = 'boiler' THEN cycles.runtime END)
        FROM
            cycles;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
