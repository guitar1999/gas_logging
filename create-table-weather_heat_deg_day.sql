BEGIN;
CREATE TABLE weather_heat_deg_day (
    whddid serial NOT NULL PRIMARY KEY,
    date date NOT NULL UNIQUE,
    hdd integer NOT NULL
);
COMMIT;
