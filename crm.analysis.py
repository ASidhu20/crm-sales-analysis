import pandas as pd
import sqlite3
import matplotlib.pyplot as plt

# Connect to your actual database
conn = sqlite3.connect("/Users/akalvijay/Desktop/DAgtDope/crm.analysis.db")

# --- Chart 1: Monthly revenue trend ---
monthly = pd.read_sql_query("""
    SELECT strftime('%Y-%m', close_date) AS month, SUM(close_value) AS revenue
    FROM sales_pipeline
    WHERE deal_stage = 'Won'
    GROUP BY month
    ORDER BY month
""", conn)

plt.figure(figsize=(10, 5))
plt.plot(monthly["month"], monthly["revenue"], marker="o")
plt.xticks(rotation=45)
plt.title("Monthly Revenue Trend (Won Deals)")
plt.ylabel("Revenue")
plt.tight_layout()
plt.savefig("monthly_revenue.png")
plt.show()

# --- Chart 2: Revenue by sector ---
sector = pd.read_sql_query("""
    SELECT a.sector, SUM(sp.close_value) AS total_revenue
    FROM sales_pipeline sp
    JOIN accounts a ON sp.account = a.account
    WHERE sp.deal_stage = 'Won'
    GROUP BY a.sector
    ORDER BY total_revenue DESC
""", conn)

plt.figure(figsize=(10, 5))
plt.bar(sector["sector"], sector["total_revenue"])
plt.xticks(rotation=45)
plt.title("Total Revenue by Sector (Won Deals)")
plt.ylabel("Revenue")
plt.tight_layout()
plt.savefig("revenue_by_sector.png")
plt.show()

conn.close()

print("Done. Charts saved as monthly_revenue.png and revenue_by_sector.png")