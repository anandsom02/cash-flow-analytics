
-- ============================================
-- Project: Cash Flow Analytics & Forecasting
-- Database: cash_flow_analytics
-- Description: SQL analysis of cash transactions
-- ============================================

USE cash_flow_analytics;


-- 1. Total completed inflow, outflow and net cash flow

SELECT
    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount ELSE 0
    END) AS Total_Inflow,

    SUM(CASE
        WHEN Transaction_Type = 'Outflow'
        THEN Amount ELSE 0
    END) AS Total_Outflow,

    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount
        WHEN Transaction_Type = 'Outflow'
        THEN -Amount
        ELSE 0
    END) AS Net_Cash_Flow

FROM cash_transactions
WHERE Status = 'Completed';


-- 2. Monthly cash flow analysis

SELECT
    DATE_FORMAT(Date, '%Y-%m') AS Month,

    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount ELSE 0
    END) AS Monthly_Inflow,

    SUM(CASE
        WHEN Transaction_Type = 'Outflow'
        THEN Amount ELSE 0
    END) AS Monthly_Outflow,

    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount
        WHEN Transaction_Type = 'Outflow'
        THEN -Amount
        ELSE 0
    END) AS Net_Cash_Flow

FROM cash_transactions
WHERE Status = 'Completed'
GROUP BY DATE_FORMAT(Date, '%Y-%m')
ORDER BY Month;


-- 3. Expense category analysis

SELECT
    Category,
    SUM(Amount) AS Total_Expense,
    ROUND(
        SUM(Amount) * 100.0 /
        (SELECT SUM(Amount)
         FROM cash_transactions
         WHERE Status = 'Completed'
           AND Transaction_Type = 'Outflow'),
        2
    ) AS Expense_Percentage

FROM cash_transactions
WHERE Status = 'Completed'
  AND Transaction_Type = 'Outflow'
GROUP BY Category
ORDER BY Total_Expense DESC;


-- 4. Yearly cash flow analysis

SELECT
    YEAR(Date) AS Year,

    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount ELSE 0
    END) AS Total_Inflow,

    SUM(CASE
        WHEN Transaction_Type = 'Outflow'
        THEN Amount ELSE 0
    END) AS Total_Outflow,

    SUM(CASE
        WHEN Transaction_Type = 'Inflow'
        THEN Amount
        WHEN Transaction_Type = 'Outflow'
        THEN -Amount
        ELSE 0
    END) AS Net_Cash_Flow

FROM cash_transactions
WHERE Status = 'Completed'
GROUP BY YEAR(Date)
ORDER BY Year;


-- 5. Year-over-year net cash flow change

WITH yearly_summary AS (
    SELECT
        YEAR(Date) AS Year,
        SUM(CASE
            WHEN Transaction_Type = 'Inflow'
                THEN Amount
            WHEN Transaction_Type = 'Outflow'
                THEN -Amount
            ELSE 0
        END) AS Net_Cash_Flow
    FROM cash_transactions
    WHERE Status = 'Completed'
    GROUP BY YEAR(Date)
),
yearly_comparison AS (
    SELECT
        Year,
        Net_Cash_Flow,
        LAG(Net_Cash_Flow) OVER (
            ORDER BY Year
        ) AS Previous_Year_Cash_Flow
    FROM yearly_summary
)
SELECT
    Year,
    ROUND(Net_Cash_Flow, 2) AS Net_Cash_Flow,
    ROUND(Previous_Year_Cash_Flow, 2)
        AS Previous_Year_Cash_Flow,
    ROUND(
        (Net_Cash_Flow - Previous_Year_Cash_Flow)
        * 100.0 / NULLIF(Previous_Year_Cash_Flow, 0),
        2
    ) AS YoY_Change_Percentage
FROM yearly_comparison
ORDER BY Year;


-- 6. Highest and lowest monthly net cash flow

WITH monthly_summary AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS Month,
        SUM(CASE
            WHEN Transaction_Type = 'Inflow'
                THEN Amount
            WHEN Transaction_Type = 'Outflow'
                THEN -Amount
            ELSE 0
        END) AS Net_Cash_Flow
    FROM cash_transactions
    WHERE Status = 'Completed'
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
)
SELECT
    Month,
    ROUND(Net_Cash_Flow, 2) AS Net_Cash_Flow,
    CASE
        WHEN Net_Cash_Flow = (
            SELECT MAX(Net_Cash_Flow)
            FROM monthly_summary
        ) THEN 'Highest'
        WHEN Net_Cash_Flow = (
            SELECT MIN(Net_Cash_Flow)
            FROM monthly_summary
        ) THEN 'Lowest'
    END AS Cash_Flow_Status
FROM monthly_summary
WHERE Net_Cash_Flow = (
    SELECT MAX(Net_Cash_Flow)
    FROM monthly_summary
)
OR Net_Cash_Flow = (
    SELECT MIN(Net_Cash_Flow)
    FROM monthly_summary
)
ORDER BY Net_Cash_Flow DESC;
