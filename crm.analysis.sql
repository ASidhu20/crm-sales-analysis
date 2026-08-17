-- 1. Overall pipeline breakdown (sanity check, already done)
SELECT deal_stage, COUNT(*) FROM sales_pipeline GROUP BY deal_stage;

-- 2. Total revenue by industry sector (JOIN with accounts)
SELECT a.sector, SUM(sp.close_value) AS total_revenue
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY a.sector
ORDER BY total_revenue DESC;

-- 3. Win rate per sales agent (CTE + CASE WHEN)
WITH agent_totals AS (
    SELECT sales_agent,
        COUNT(*) AS total_deals,
        SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals
    FROM sales_pipeline
    WHERE deal_stage IN ('Won', 'Lost')
    GROUP BY sales_agent
)
SELECT sales_agent, total_deals, won_deals,
    ROUND(100.0 * won_deals / total_deals, 1) AS win_rate_pct
FROM agent_totals
ORDER BY win_rate_pct DESC;

-- 4. Revenue by regional office (JOIN with sales_teams)
SELECT st.regional_office, SUM(sp.close_value) AS total_revenue
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY total_revenue DESC;

-- 5. Top products by total revenue and average deal size
SELECT product,
    COUNT(*) AS deals_won,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_size
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY total_revenue DESC;

-- 6. Average deal cycle time in days (engage to close, won deals only)
SELECT ROUND(AVG(JULIANDAY(close_date) - JULIANDAY(engage_date)), 1) AS avg_days_to_close
FROM sales_pipeline
WHERE deal_stage = 'Won';

-- 7. Top 3 sales agents by revenue WITHIN each regional office (CTE + window function)
WITH agent_revenue AS (
    SELECT st.regional_office, sp.sales_agent, SUM(sp.close_value) AS revenue
    FROM sales_pipeline sp
    JOIN sales_teams st ON sp.sales_agent = st.sales_agent
    WHERE sp.deal_stage = 'Won'
    GROUP BY st.regional_office, sp.sales_agent
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY regional_office ORDER BY revenue DESC) AS rnk
    FROM agent_revenue
)
SELECT * FROM ranked WHERE rnk <= 3;

-- 8. Monthly revenue trend with running total (CTE + window function)
WITH monthly AS (
    SELECT strftime('%Y-%m', close_date) AS month, SUM(close_value) AS monthly_revenue
    FROM sales_pipeline
    WHERE deal_stage = 'Won'
    GROUP BY month
)
SELECT month, monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;

-- 9. Revenue and deals won per manager (JOIN with sales_teams)
SELECT st.manager, COUNT(*) AS deals_won, SUM(sp.close_value) AS total_revenue
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.manager
ORDER BY total_revenue DESC;

-- 10. Win rate by sector (CTE + JOIN + CASE WHEN)
WITH sector_stats AS (
    SELECT a.sector,
        COUNT(*) AS total_deals,
        SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals
    FROM sales_pipeline sp
    JOIN accounts a ON sp.account = a.account
    WHERE sp.deal_stage IN ('Won', 'Lost')
    GROUP BY a.sector
)
SELECT sector, total_deals, won_deals,
    ROUND(100.0 * won_deals / total_deals, 1) AS win_rate_pct
FROM sector_stats
ORDER BY win_rate_pct DESC;