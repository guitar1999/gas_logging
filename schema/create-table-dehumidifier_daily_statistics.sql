CREATE TABLE dehumidifier_daily_statistics (
    ddsid SERIAL NOT NULL PRIMARY KEY,
    date DATE NOT NULL,
    total_kwh NUMERIC,
    total_runtime_hours NUMERIC,
    avg_runtime_minutes NUMERIC,
    min_runtime_minutes NUMERIC,
    max_runtime_minutes NUMERIC,
    cycles INTEGER
);
