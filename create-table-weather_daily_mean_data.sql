BEGIN;
CREATE TABLE weather_daily_mean_data (
    wdmdid serial NOT NULL PRIMARY KEY,
    date date NOT NULL UNIQUE,
    hdd integer NOT NULL, 
    mean_dewpoint integer,
    mean_pressure numeric,
    mean_temperature integer,
    mean_visibility integer,
    mean_wind_direction integer,
    mean_wind_speed integer
);
COMMIT;
