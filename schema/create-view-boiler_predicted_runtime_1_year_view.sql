CREATE VIEW oil_statistics.boiler_predicted_runtime_1_year_view AS (
    SELECT
        gs::DATE AS date,
        hdd.doy,
        CASE s.season
            WHEN 'spring' THEN
            CASE
                WHEN DATE_PART('DOW', gs) IN (0,6) THEN -0.005119 * hdd ^ 3 + 0.610510 * hdd ^ 2 - 6.420110 * hdd + 95.970912
                ELSE -0.000559 * hdd ^ 4 + 0.039681 * hdd ^ 3 - 0.509963 * hdd ^ 2 + 4.128802 * hdd + 56.122516
            END
            WHEN 'summer' THEN
            CASE
                WHEN DATE_PART('DOW', gs) IN (0,6) THEN 63.50494
                ELSE 56.70688
            END
            WHEN 'fall' THEN
            CASE
                WHEN DATE_PART('DOW', gs) IN (0,6) THEN -0.001182 * hdd ^ 4 + 0.057871 * hdd ^ 3 - 0.443580 * hdd ^ 2 + 2.450336 * hdd + 54.303062
                ELSE -0.02345 * hdd ^ 3 + 1.38611 * hdd ^ 2 - 10.36148 * hdd + 65.96960
            END
            WHEN 'winter' THEN
            CASE
                WHEN DATE_PART('DOW', gs) IN (0,6) THEN 0.0008518 * hdd ^ 4 - 0.1139575 * hdd ^ 3 + 5.5227733 * hdd ^ 2 - 101.0668277 * hdd + 813
                ELSE 0.00001031 * hdd ^ 5 - 0.00130760 * hdd ^ 4 + 0.03468729 * hdd ^ 3 + 1.47757949 * hdd ^ 2 - 67.43478419 * hdd + 942.79250606
            END
        END AS predicted_runtime
    FROM
        generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '365 DAYS', '1 DAY') AS gs
        INNER JOIN oil_statistics.heating_degree_days_view hdd ON DATE_PART('DOY', gs) = hdd.doy
        INNER JOIN weather_data.meteorological_season s ON hdd.doy=s.doy
    ORDER BY
        1
);
