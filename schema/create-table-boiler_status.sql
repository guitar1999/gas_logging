BEGIN;
CREATE TABLE oil.boiler_status (
    bsid SERIAL NOT NULL PRIMARY KEY,
    status TEXT CHECK (status = 'ON' OR status = 'OFF'),
    status_time TIMESTAMP WITH TIME ZONE
);
COMMIT;
