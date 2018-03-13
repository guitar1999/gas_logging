CREATE OR REPLACE VIEW oil_plotting.cumulative_predicted_use_this_month_view AS (
    WITH today AS (
        SELECT
            sum_date,
            runtime,
            1 - DATE_PART('HOUR', CURRENT_TIMESTAMP) / 24.0 AS rem_day_pct
        FROM
            oil_statistics.oil_sums_daily_view
        WHERE
            sum_date = CURRENT_DATE
        ), cumulative_sum AS (
        SELECT
            date,
            predicted_runtime,
            SUM(predicted_runtime) OVER (ORDER BY date) AS sum
        FROM
            oil_statistics.boiler_predicted_runtime_1_year_view
        WHERE
            date < DATE_TRUNC('MONTH', CURRENT_DATE + INTERVAL '1 MONTH')
        )
        SELECT
            (c.date || ' 23:59:59')::TIMESTAMP,
            GREATEST(t.runtime + c.sum * t.rem_day_pct, c.sum) - t.runtime + m.runtime AS runtime -- if we've already run more than predicted, add that to the percent of day left * the prediction, otherwise use the prediction. Then subtract today's runtime (because it's already in ->) and add the month's runtime. Phew!
        FROM
            cumulative_sum c,
            today t,
            (SELECT
                runtime
            FROM
                oil_statistics.oil_sums_monthly_view
            WHERE
                DATE_PART('YEAR', CURRENT_DATE) = year AND DATE_PART('MONTH', CURRENT_DATE) = month
            ) AS m
);

