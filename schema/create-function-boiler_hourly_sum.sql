CREATE OR REPLACE FUNCTION boiler_hourly_sum() RETURNS TRIGGER AS 
$$
    DECLARE
        old_hour INTEGER;
    BEGIN
        SELECT DATE_PART('HOUR', (SELECT MAX(measurement_time) FROM electricity_iotawatt.electricity_measurements WHERE NOT emid = NEW.emid AND measurement_time < NEW.measurement_time)) INTO old_hour;
        IF old_hour = DATE_PART('HOUR', NEW.measurement_time) -1 THEN
            INSERT INTO oil_statistics.oil_sums_hourly (sum_date, hour, btu, runtime)
            SELECT (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::DATE AS sum_date,
            DATE_PART('HOUR', DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL) AS hour,
            COALESCE(bs.btu, 0),
            COALESCE(bs.total_boiler_runtime, 0)
            FROM boiler_summary( 
                (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP, (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP + '00:59:59'::INTERVAL ) AS bs;
            RETURN NEW;
        ELSE
            RETURN NEW;
        END IF;
    END;
$$
LANGUAGE PLPGSQL VOLATILE;


DROP TRIGGER IF EXISTS boiler_hourly_sum ON electricity_iotawatt.electricity_measurements;
CREATE TRIGGER boiler_hourly_sum
    AFTER INSERT ON electricity_iotawatt.electricity_measurements FOR EACH ROW EXECUTE PROCEDURE boiler_hourly_sum();