CREATE OR REPLACE VIEW oil.boiler_is_on_view AS (
  SELECT
    (m.watts_boiler >= t.boiler_kwh) AS is_on
  FROM
    (SELECT measurement_time, watts_boiler
    FROM electricity_iotawatt.electricity_measurements
    ORDER BY measurement_time DESC
    LIMIT 1) AS m
  CROSS JOIN
    (SELECT boiler_kwh
    FROM oil.boiler_thresholds
    ORDER BY change_time DESC
    LIMIT 1) AS t
);
