CREATE TABLE weather_data.heating_season (
    month INTEGER NOT NULL PRIMARY KEY CHECK (month > 0 AND month < 13),
    season TEXT NOT NULL CHECK (season IN ('heat', 'noheat', 'shoulder'))
);
