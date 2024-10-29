CREATE OR REPLACE FUNCTION circulator_summary(start_date timestamp, end_date timestamp) 
RETURNS TABLE(circulator_cycles integer, total_circulator_runtime numeric, avg_circulator_runtime numeric, min_circulator_runtime numeric, max_circulator_runtime numeric)
AS $$
BEGIN
    RETURN QUERY WITH cycles AS (
        SELECT 
            b.event_group, 
            b.system_status, 
            SUM(b.tdiff) / 60 AS runtime, 
            SUM(b.btu) AS btu, 
            SUM(b.watts * b.tdiff / 1000 / 60 / 60) AS kwh 
        FROM 
            circulator_status(start_date, end_date) b
        GROUP BY 
            event_group, 
            system_status 
        ORDER BY 
            event_group,
            system_status
        ) SELECT
            COALESCE(COUNT(cycles.*) FILTER (WHERE cycles.system_status = 'circulator'), 0)::INTEGER,
            COALESCE(SUM(cycles.runtime) FILTER (WHERE cycles.system_status = 'circulator'), 0)::NUMERIC,
            COALESCE(AVG(cycles.runtime) FILTER (WHERE cycles.system_status = 'circulator'), 0)::NUMERIC,
            COALESCE(MIN(cycles.runtime) FILTER (WHERE cycles.system_status = 'circulator'), 0)::NUMERIC,
            COALESCE(MAX(cycles.runtime) FILTER (WHERE cycles.system_status = 'circulator'), 0)::NUMERIC
        FROM
            cycles;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
