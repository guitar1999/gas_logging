BEGIN;
CREATE TABLE dehumidifier_status (
    dsid SERIAL NOT NULL PRIMARY KEY,
    status TEXT CHECK (status = 'ON' OR status = 'OFF'),
    status_time TIMESTAMP WITH TIME ZONE
);
COMMIT;
