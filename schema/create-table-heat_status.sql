BEGIN;
CREATE TABLE oil.heat_status (
    hsid SERIAL NOT NULL PRIMARY KEY,
    status TEXT CHECK (status = 'ON' OR status = 'OFF'),
    status_time TIMESTAMP WITH TIME ZONE
);
COMMIT;
