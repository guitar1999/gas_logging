WITH kwh_query AS (select measurement_time, date_part('year', measurement_time) AS year, sum((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) OVER (ORDER BY measurement_time) AS kwh FROM electricity_measurements WHERE date_part('year', measurement_time) = 2013) SELECT min(measurement_time) FROM kwh_query WHERE kwh > 2000;


WITH statustable AS (
    SELECT 
        watts_ch3, 
        tdiff, 
        measurement_time,
        CASE WHEN watts_ch3 > 490 THEN 'ON'::text ELSE 'OFF'::text END AS status
    FROM 
        electricity_measurements 
    WHERE 
        measurement_time::date = (CURRENT_TIMESTAMP - interval '1 day')::date
), optable AS (
    SELECT 
        watts_ch3, 
        tdiff, 
        measurement_time, 
        status, 
        CASE WHEN status = 'OFF' THEN NULL
            WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'OFF' THEN date_part('epoch', measurement_time )
            WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'ON' THEN NULL
        END AS event_group
    FROM 
        statustable
), partition_query AS (
    SELECT 
        watts_ch3,
        tdiff,
        measurement_time,
        status,
        CASE WHEN status = 'OFF' THEN NULL ELSE sum(CASE WHEN event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY measurement_time) END AS event_group
    FROM
        optable
    ORDER BY 
        measurement_time ASC
), events AS (
    SELECT 
        event_group, 
        sum(tdiff) / 60 AS runtime 
    FROM 
        partition_query 
    WHERE
        status = 'ON'
    GROUP BY 
        event_group 
) SELECT 
    round(sum(runtime) / 60, 2) AS total_hours,
    round(avg(runtime), 2) AS avg_minutes,
    round(min(runtime), 2) AS min_minutes,
    round(max(runtime), 2) AS max_minutes,
    count(runtime) AS cycles
 FROM 
    events;

SELECT 
    round(sum(runtime) / 60, 2) AS total_hours,
    round(avg(runtime), 2) AS avg_minutes,
    round(min(runtime), 2) AS min_minutes,
    round(max(runtime), 2) AS max_minutes,
    count(runtime) AS cycles
 FROM 
    (SELECT 
        event_group, 
        sum(tdiff) / 60 AS runtime 
    FROM 
        (SELECT 
        watts_ch3,
        tdiff,
        measurement_time,
        status,
        CASE WHEN status = 'OFF' THEN NULL ELSE sum(CASE WHEN event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY measurement_time) END AS event_group
    FROM
        (SELECT 
        watts_ch3, 
        tdiff, 
        measurement_time, 
        status, 
        CASE WHEN status = 'OFF' THEN NULL
            WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'OFF' THEN date_part('epoch', measurement_time )
            WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'ON' THEN NULL
        END AS event_group
    FROM 
        (SELECT 
        watts_ch3, 
        tdiff, 
        measurement_time,
        CASE WHEN watts_ch3 > 490 THEN 'ON'::text ELSE 'OFF'::text END AS status
    FROM 
        electricity_measurements 
    WHERE 
        measurement_time::date = (CURRENT_TIMESTAMP - interval '1 day')::date) AS a) AS z
    ORDER BY 
        measurement_time ASC) AS y 
    WHERE
        status = 'ON'
    GROUP BY 
        event_group) AS x;


SELECT round(sum(runtime) / 60, 2) AS total_hours, round(avg(runtime), 2) AS avg_minutes, round(min(runtime), 2) AS min_minutes, round(max(runtime), 2) AS max_minutes, count(runtime) AS cycles FROM (SELECT event_group, sum(tdiff) / 60 AS runtime FROM (SELECT watts_ch3, tdiff, measurement_time, status, CASE WHEN status = 'OFF' THEN NULL ELSE sum(CASE WHEN event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY measurement_time) END AS event_group FROM (SELECT watts_ch3, tdiff, measurement_time, status, CASE WHEN status = 'OFF' THEN NULL WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'OFF' THEN date_part('epoch', measurement_time ) WHEN status = 'ON' AND LAG(status) OVER (ORDER BY measurement_time) = 'ON' THEN NULL END AS event_group FROM (SELECT watts_ch3, tdiff, measurement_time, CASE WHEN watts_ch3 > 490 THEN 'ON'::text ELSE 'OFF'::text END AS status FROM electricity_measurements WHERE measurement_time::date = (CURRENT_TIMESTAMP - interval '1 day')::date) AS a) AS z ORDER BY measurement_time ASC) AS y WHERE status = 'ON' GROUP BY event_group) AS x;
