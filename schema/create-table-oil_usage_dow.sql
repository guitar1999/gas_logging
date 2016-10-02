CREATE TABLE oil.oil_usage_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    day_of_week text,
    btu numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (0, 'Sunday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (1, 'Monday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (2, 'Tuesday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (3, 'Wednesday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (4, 'Thursday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (5, 'Friday', 0, 'no', CURRENT_TIMESTAMP);
INSERT INTO oil.oil_usage_dow (dow, day_of_week, btu, complete, updated) VALUES (6, 'Saturday', 0, 'no', CURRENT_TIMESTAMP);
