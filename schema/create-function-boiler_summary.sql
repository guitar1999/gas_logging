CREATE OR REPLACE FUNCTION boiler_summary(start_date timestamp, end_date timestamp)
RETURNS TABLE(btu numeric, gallons numeric, kwh numeric, boiler_cycles integer, total_boiler_runtime numeric, avg_boiler_runtime numeric, min_boiler_runtime numeric, max_boiler_runtime numeric)
AS $$
BEGIN
    RETURN QUERY WITH cycles AS (
        SELECT
            b.event_group,
            b.system_status,
            SUM(CASE WHEN b.tdiff > 600 THEN 10 ELSE b.tdiff END) / 60 AS runtime, -- Admittedly, a hack, but we need to clean up tdiffs on insert for gaps
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
            COALESCE(SUM(cycles.btu) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC,
            COALESCE(SUM(cycles.gallons) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC,
            COALESCE(SUM(cycles.kwh), 0)::NUMERIC,
            COALESCE(COUNT(cycles.*) FILTER (WHERE cycles.system_status = 'boiler'), 0)::INTEGER,
            COALESCE(SUM(cycles.runtime) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC,
            COALESCE(AVG(cycles.runtime) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC,
            COALESCE(MIN(cycles.runtime) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC,
            COALESCE(MAX(cycles.runtime) FILTER (WHERE cycles.system_status = 'boiler'), 0)::NUMERIC
        FROM
            cycles;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
