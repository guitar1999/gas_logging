CREATE OR REPLACE FUNCTION furnace_status(start_date timestamp, end_date timestamp) 
RETURNS TABLE(watts integer, measurement_time timestamp with time zone, tdiff numeric, main_status text, system_status text, heatcall integer, btu numeric, event_group integer)
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
            --e.measurement_time = f.status_time
            to_timestamp(e.measurement_time::text, 'YYYY-MM-DD HH24:MI') = to_timestamp(f.status_time::text, 'YYYY-MM-DD HH24:MI')
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
                WHEN s.status = 'ON' AND s.watts >= 40 AND s.watts < 69 THEN 'blower'
                WHEN s.status = 'ON' AND s.watts < 40 THEN 'main power'
                WHEN s.status = 'ON' AND s.watts > 500 THEN 'dehumidification'
                WHEN s.status = 'OFF' THEN 'off'
                ELSE 'heating'
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
                WHEN NOT s2.status2 = 'heating' THEN NULL
                WHEN s2.status2 = 'heating' AND NOT LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'heating' THEN date_part('epoch', s2.measurement_time)
                WHEN s2.status2 = 'heating' AND LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'heating' THEN NULL
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
                WHEN NOT e.status2 = 'heating' THEN NULL 
                ELSE sum(CASE WHEN e.event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY e.measurement_time)
            END AS event_group
        FROM event_group_query e
    ), durations AS (
        SELECT
            e2.event_group,
            sum(e2.tdiff) AS duration
        FROM 
            event_group2_query e2
        WHERE 
            NOT e2.event_group IS NULL
        GROUP BY
            e2.event_group
        ORDER by
            e2.event_group
    ), heatcall_query AS (
        SELECT 
            e2.*,
            CASE
                WHEN d.duration < 72 AND e2.status2 = 'heating' THEN 'startup'
                ELSE e2.status2
            END AS status3,
            CASE
                WHEN e2.status2 = 'heating' AND d.duration >= 72 THEN 
                CASE 
                    WHEN ROUND(3.458e-10 * e2.watts^5 - 4.174e-07 * e2.watts^4 + 1.943e-04 * e2.watts^3 - 4.411e-02 * e2.watts^2 + 5.065e+00 * e2.watts - 1.564e+02) > 100 THEN 100
                    WHEN ROUND(3.458e-10 * e2.watts^5 - 4.174e-07 * e2.watts^4 + 1.943e-04 * e2.watts^3 - 4.411e-02 * e2.watts^2 + 5.065e+00 * e2.watts - 1.564e+02) < 40 THEN 40
                    ELSE ROUND(3.458e-10 * e2.watts^5 - 4.174e-07 * e2.watts^4 + 1.943e-04 * e2.watts^3 - 4.411e-02 * e2.watts^2 + 5.065e+00 * e2.watts - 1.564e+02)
                END
                ELSE 0
            END AS heatcall,
            d.duration 
        FROM
            event_group2_query e2 LEFT JOIN durations d ON e2.event_group=d.event_group
    )
        SELECT
            h.watts,
            h.measurement_time,
            h.tdiff, 
            h.status AS main_status, 
            h.status3 AS system_status, 
            h.heatcall::integer AS heatcall,
            (h.heatcall / 100. * 60000 * h.tdiff / 60 / 60)::numeric AS btu, 
            h.event_group::integer AS event_group
        FROM
            heatcall_query h;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
