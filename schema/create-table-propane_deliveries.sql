CREATE TABLE propane.propane_deliveries (
	delivery_date DATE NOT NULL,
	gallons NUMERIC NOT NULL,
	fill BOOLEAN NOT NULL DEFAULT true
);
