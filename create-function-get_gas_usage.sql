CREATE OR REPLACE FUNCTION get_gas_usage(start_date date, end_date date) 
RETURNS TABLE(watts integer, measurement_time timestamp with time zone, tdiff numeric, status text)
AS $$
-- Declare an empty variable to hold the initial state of the system
DECLARE

    initial_state TEXT;
    min_meas_time TIMESTAMP WITH TIME ZONE;

BEGIN

    -- Get the initial state of the system
    SELECT furnace_status.status INTO initial_state FROM furnace_status WHERE status_time = (SELECT max(status_time) FROM furnace_status WHERE status_time < start_date);
    -- Replaced below with above
    --WITH state_query AS (
    --  SELECT status AS initial_state FROM furnace_status WHERE status_time = (SELECT max(status_time) FROM furnace_status WHERE status_time < '2014-05-09')
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
            furnace_status f
        ON
            e.measurement_time = f.status_time
            --to_timestamp(e.measurement_time::text, 'YYYY-MM-DD HH24:MI') = to_timestamp(f.status_time::text, 'YYYY-MM-DD HH24:MI')
        WHERE 
            e.measurement_time >= start_date AND
            e.measurement_time < end_date 
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
    ) SELECT
            p.watts,
            p.measurement_time,
            p.tdiff,
            first_value(p.status) OVER (partition by value_partition ORDER BY p.measurement_time) AS status
        FROM 
            partition_query p;
END;
$$ LANGUAGE plpgsql;
