CREATE TABLE oil_statistics.oil_cumulative_predictions (
    ocpid SERIAL NOT NULL PRIMARY KEY,
    prediction_rundate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    predicted_timestamp TIMESTAMP WITH TIME ZONE,
    predicted_runtime NUMERIC
);
