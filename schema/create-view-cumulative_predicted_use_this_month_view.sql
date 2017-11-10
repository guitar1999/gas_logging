CREATE OR REPLACE VIEW oil_plotting.cumulative_predicted_use_this_month_view AS (
    WITH today AS (
        SELECT 
            sum_date, 
            runtime 
        FROM 
            oil_statistics.oil_sums_daily_view
        WHERE
            sum_date = CURRENT_DATE
        ), cumulative_sum AS (
        SELECT 
            date, 
            predicted_runtime, 
            SUM(predicted_runtime) OVER (ORDER BY date) 
        FROM 
            oil_statistics.boiler_predicted_runtime_1_year_view
        WHERE
            date < DATE_TRUNC('MONTH', CURRENT_DATE + INTERVAL '1 MONTH')
        ) 
        SELECT 
            (date || ' 23:59:59')::TIMESTAMP, GREATEST(t.runtime, sum) - t.runtime + m.runtime AS runtime 
        FROM 
            cumulative_sum, 
            today t, 
            (SELECT 
                runtime 
            FROM 
                oil_statistics.oil_sums_monthly_view
            WHERE
                DATE_PART('YEAR', CURRENT_DATE) = year AND DATE_PART('MONTH', CURRENT_DATE) = month
            ) AS m
);

