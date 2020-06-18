CREATE OR REPLACE FUNCTION boiler_status(start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS TABLE(watts NUMERIC, measurement_time TIMESTAMP WITH TIME ZONE, tdiff NUMERIC, main_status TEXT, system_status TEXT, btu NUMERIC, gallons NUMERIC, event_group INTEGER)
AS $$
-- Declare an empty variable to hold the initial state of the system and some constants to be used in calculations.
DECLARE

    initial_state TEXT;
    initial_threshold INTEGER;
    min_meas_time TIMESTAMP WITH TIME ZONE;
    oil_btu_gal INTEGER := 140000;
    nozzle_gal_hr NUMERIC := 0.666205227383988;

BEGIN

    -- Get the initial state of the system
    SELECT boiler_status.status INTO initial_state FROM boiler_status WHERE status_time = (SELECT MAX(status_time) FROM boiler_status WHERE status_time < start_date);
    -- Replaced below with above
    --WITH state_query AS (
    --  SELECT status AS initial_state FROM boiler_status WHERE status_time = (SELECT max(status_time) FROM boiler_status WHERE status_time < '2014-05-09')
    --),

    -- Get the initial threshold for detecting status
    SELECT boiler_thresholds.boiler_kwh INTO initial_threshold FROM boiler_thresholds WHERE change_time = (SELECT MAX(change_time) FROM boiler_thresholds WHERE change_time < start_date);

    -- Get the minimum measurement_time for the given period
    SELECT MIN(electricity_measurements.measurement_time) INTO min_meas_time FROM electricity_iotawatt.electricity_measurements WHERE electricity_measurements.measurement_time >= start_date AND electricity_measurements.measurement_time <= end_date;

   RETURN QUERY WITH join_query AS (
        SELECT
            e.watts_boiler AS watts,
            e.measurement_time,
            EXTRACT('EPOCH' FROM e.measurement_time - LAG(e.measurement_time) OVER (ORDER BY e.measurement_time))::NUMERIC AS tdiff,
            CASE
                WHEN e.measurement_time = min_meas_time THEN initial_state
                ELSE f.status
            END AS status,
            CASE
                WHEN e.measurement_time = min_meas_time THEN initial_threshold
                ELSE t.boiler_kwh
            END AS threshold
        FROM
            electricity_iotawatt.electricity_measurements e
        LEFT JOIN
            boiler_status f
            ON TO_TIMESTAMP(e.measurement_time::TEXT, 'YYYY-MM-DD HH24:MI') = TO_TIMESTAMP(f.status_time::TEXT, 'YYYY-MM-DD HH24:MI')
        LEFT JOIN
            boiler_thresholds t
            ON TO_TIMESTAMP(e.measurement_time::TEXT, 'YYYY-MM-DD HH24:MI') = TO_TIMESTAMP(t.change_time::TEXT, 'YYYY-MM-DD HH24:MI')
        WHERE
            e.measurement_time >= start_date AND
            e.measurement_time <= end_date AND
            NOT e.watts_boiler IS NULL
    ), partition_query AS (
        SELECT
            j.watts,
            j.measurement_time,
            j.tdiff,
            j.status,
            j.threshold,
            SUM(CASE WHEN j.status IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY j.measurement_time) AS value_partition,
            SUM(CASE WHEN j.threshold IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY j.measurement_time) AS threshold_partition
        FROM
            join_query j
        ORDER BY j.measurement_time ASC
    ), status1_query AS (
        SELECT
            p.watts,
            p.measurement_time,
            p.tdiff,
            FIRST_VALUE(p.status) OVER (PARTITION BY value_partition ORDER BY p.measurement_time) AS status,
            FIRST_VALUE(p.threshold) OVER (PARTITION BY threshold_partition ORDER BY p.measurement_time) AS threshold
        FROM
            partition_query p
    ), status2_query AS (
        SELECT
            s.watts,
            s.measurement_time,
            s.tdiff,
            s.status,
            CASE
                WHEN s.status = 'ON' AND s.watts < s.threshold THEN 'main power'
                WHEN s.status = 'ON' AND s.watts >= s.threshold THEN 'boiler'
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
                WHEN NOT s2.status2 = 'boiler' THEN NULL
                WHEN s2.status2 = 'boiler' AND NOT LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'boiler' THEN DATE_PART('EPOCH', s2.measurement_time)
                WHEN s2.status2 = 'boiler' AND LAG(s2.status2) OVER (ORDER BY s2.measurement_time) = 'boiler' THEN NULL
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
                WHEN NOT e.status2 IN ('boiler', 'circulator') THEN NULL
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
                WHEN e2.status2 = 'boiler' THEN (oil_btu_gal * nozzle_gal_hr * CASE WHEN e2.tdiff > 600 THEN 10 ELSE e2.tdiff END / 60 / 60)::NUMERIC
                ELSE 0::NUMERIC
            END AS btu,
            CASE
                WHEN e2.status2 = 'boiler' THEN (nozzle_gal_hr  * CASE WHEN e2.tdiff > 600 THEN 10 ELSE e2.tdiff END / 60 / 60)::NUMERIC
                ELSE 0::NUMERIC
            END AS gallons,
            e2.event_group::INTEGER AS event_group
        FROM
            event_group2_query e2;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

