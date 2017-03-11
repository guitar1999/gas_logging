CREATE OR REPLACE FUNCTION furnace_btu(start_date timestamp, end_date timestamp) 
RETURNS numeric
AS $$
BEGIN
    RETURN (
    SELECT 
        sum(btu) AS btu
    FROM
        furnace_status(start_date, end_date)
    );
END;
$$ LANGUAGE plpgsql;
