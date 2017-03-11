CREATE OR REPLACE FUNCTION circulator_status(start_date timestamp, end_date timestamp) 
RETURNS TABLE(watts integer, measurement_time timestamp with time zone, tdiff numeric, main_status text, system_status text, btu numeric, event_group integer)
AS $$
-- Declare an empty variable to hold the initial state of the system
DECLARE

    initial_state TEXT;
    min_meas_time TIMESTAMP WITH TIME ZONE;

BEGIN

    -- Get the initial state of the system
    SELECT boiler_status.status INTO initial_state FROM boiler_status WHERE status_time = (SELECT max(status_time) FROM boiler_status WHERE status_time < start_date);
    -- Replaced below with above
    --WITH state_query AS (
    --  SELECT status AS initial_state FROM boiler_status WHERE status_time = (SELECT max(status_time) FROM boiler_status WHERE status_time < '2014-05-09')
    --), 
    
    -- Get the minimum measurement_time for the given period
    SELECT min(electricity_measurements.measurement_time) INTO min_meas_time FROM electricity_measurements WHERE electricity_measurements.measurement_time >= start_date AND electricity_measurements.measurement_time <= end_date;

   RETURN QUERY  WITH join_query AS (
        SELECT
            e.watts_ch3 AS watts, 
            e.measurement_time,
            e.tdiff,
            CASE 
                WHEN e.measurement_time = min_meas_time THEN initial_state
                ELSE f.status
            END AS status
        FROM
            electricity_measurements e
        LEFT JOIN
            boiler_status f
        ON
            --e.measurement_time = f.status_time
            to_timestamp(e.measurement_time::text, 'YYYY-MM-DD HH24:MI') = to_timestamp(f.status_time::text, 'YYYY-MM-DD HH24:MI')
        WHERE 
            e.measurement_time >= start_date AND
            e.measurement_time <= end_date 
    ), partition_query AS (
        SELECT 
            j.watts, 
            j.measurement_time, 
            j.tdiff, 
            j.status,
            sum(CASE WHEN j.status IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY j.measurement_time) AS value_partition
        FROM
            join_query j
        ORDER BY j.measurement_time ASC
    ), status1_query AS (
        SELECT
            p.watts,
            p.measurement_time,
            p.tdiff,
            first_value(p.status) OVER (partition by value_partition ORDER BY p.measurement_time) AS status
        FROM
            partition_query p
    ), status2_query AS (
        SELECT 
            s.watts,
            s.measurement_time,
            s.tdiff,
            s.status,
            CASE 
                WHEN s.status = 'ON' AND s.watts < 50 THEN 'main power'
                WHEN s.status = 'ON' AND s.watts >= 50 THEN 'circulator'
                -- WHEN s.status = 'ON' AND s.watts >= 200 THEN 'boiler and circulator'
                WHEN s.status = 'OFF' THEN 'OFF'
            END AS status2
        FROM 
            status1_query s
    ), event_group_query AS (
        SELECT
            s2.watts,
            s2.measurement_time,
            s2.tdiff,
            s2.status,
            s2.status2,
            CASE 
                WHEN NOT s2.status2 = 'circulator' THEN NULL
                WHEN s2.status2 = 'circulator' AND NOT LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'circulator' THEN date_part('epoch', s2.measurement_time)
                WHEN s2.status2 = 'circulator' AND LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'circulator' THEN NULL
            END AS event_group 
        FROM 
            status2_query AS s2
    ), event_group2_query AS ( 
        SELECT
            e.watts,
            e.measurement_time,
            e.tdiff,
            e.status,
            e.status2,
            CASE
                WHEN NOT e.status2 IN ('circulator') THEN NULL 
                ELSE sum(CASE WHEN e.event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY e.measurement_time)
            END AS event_group
        FROM event_group_query e
    )
        SELECT
            e2.watts,
            e2.measurement_time,
            e2.tdiff, 
            e2.status AS main_status, 
            e2.status2 AS system_status,
            CASE
                WHEN e2.status2 = 'boiler' THEN ROUND((140000 * e2.tdiff / 60 / 60), 2)::numeric
                ELSE 0::numeric
            END AS btu, 
            e2.event_group::integer AS event_group
        FROM
            event_group2_query e2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
