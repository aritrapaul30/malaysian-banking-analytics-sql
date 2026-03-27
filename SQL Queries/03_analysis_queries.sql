-- ============================================================
-- FILE: 03_analysis_queries.sql
-- PROJECT: Malaysian Banking & Fintech Analytics (Synthetic)
-- AUTHOR: Aritra Paul
-- INSTITUTION: Sunway University, Malaysia
-- DESCRIPTION: 14 business analysis queries covering branch
--              KPIs, customer segmentation, loan performance,
--              card spending, window functions & CTEs.
-- ENGINE: MySQL 8.0
-- ============================================================

USE mybank_analytics;

-- ============================================================
-- Q1: TOTAL DEPOSITS & BALANCES BY BRANCH
-- Business question: Which branches hold the most customer
-- deposits? Useful for liquidity planning.
-- ============================================================
SELECT
    b.branch_name,
    b.state,
    COUNT(DISTINCT a.account_id)                        AS total_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'savings'
          THEN a.account_id END)                        AS savings_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'current'
          THEN a.account_id END)                        AS current_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'fixed_deposit'
          THEN a.account_id END)                        AS fd_accounts,
    FORMAT(SUM(CASE WHEN a.status = 'active'
               THEN a.balance ELSE 0 END), 2)           AS total_deposits_myr,
    FORMAT(AVG(CASE WHEN a.status = 'active'
               THEN a.balance ELSE NULL END), 2)        AS avg_balance_myr
FROM branches b
LEFT JOIN accounts a    ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.state
ORDER BY SUM(CASE WHEN a.status = 'active' THEN a.balance ELSE 0 END) DESC;

-- ============================================================
-- Q2: TOP 10 CUSTOMERS BY TOTAL NET WORTH
-- Business question: Who are the bank's most valuable
-- customers? Based on combined account balances.
-- ============================================================
SELECT
    c.customer_id,
    c.full_name,
    c.income_tier,
    c.occupation,
    b.branch_name,
    COUNT(a.account_id)                                 AS total_accounts,
    FORMAT(SUM(a.balance), 2)                           AS total_balance_myr,
    FORMAT(c.monthly_income, 2)                         AS monthly_income_myr,
    ROUND(SUM(a.balance) / NULLIF(c.monthly_income, 0), 1)
                                                        AS wealth_to_income_ratio
FROM customers c
JOIN branches b     ON c.home_branch_id = b.branch_id
JOIN accounts a     ON c.customer_id    = a.customer_id
WHERE a.status = 'active'
GROUP BY c.customer_id, c.full_name, c.income_tier,
         c.occupation, b.branch_name, c.monthly_income
ORDER BY SUM(a.balance) DESC
LIMIT 10;

-- ============================================================
-- Q3: LOAN PORTFOLIO BREAKDOWN BY TYPE AND STATUS
-- Business question: What is the composition of the bank's
-- loan book? Identify risk exposure by loan type.
-- ============================================================
SELECT
    loan_type,
    status                                              AS loan_status,
    COUNT(*)                                            AS total_loans,
    FORMAT(SUM(principal_amount), 2)                    AS total_principal_myr,
    FORMAT(SUM(outstanding_balance), 2)                 AS total_outstanding_myr,
    FORMAT(AVG(interest_rate), 2)                       AS avg_interest_rate_pct,
    FORMAT(AVG(tenure_months), 0)                       AS avg_tenure_months,
    ROUND(SUM(outstanding_balance) /
          NULLIF(SUM(principal_amount), 0) * 100, 2)    AS outstanding_ratio_pct
FROM loans
GROUP BY loan_type, status
ORDER BY loan_type, status;

-- ============================================================
-- Q4: MONTHLY TRANSACTION VOLUME & VALUE TREND
-- Business question: How does transaction activity change
-- month-over-month? Identify peak banking periods.
-- ============================================================
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m')              AS txn_month,
    transaction_type,
    COUNT(*)                                            AS txn_count,
    FORMAT(SUM(amount), 2)                              AS total_amount_myr,
    FORMAT(AVG(amount), 2)                              AS avg_amount_myr,
    FORMAT(MAX(amount), 2)                              AS max_amount_myr
FROM transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m'), transaction_type
ORDER BY txn_month, transaction_type;

-- ============================================================
-- Q5: LOAN DEFAULT & DELINQUENCY RATE BY BRANCH
-- Business question: Which branches have the highest
-- default rates? Critical for credit risk monitoring.
-- ============================================================
SELECT
    b.branch_name,
    b.state,
    COUNT(l.loan_id)                                    AS total_loans,
    SUM(CASE WHEN l.status = 'active'
        THEN 1 ELSE 0 END)                              AS active_loans,
    SUM(CASE WHEN l.status = 'defaulted'
        THEN 1 ELSE 0 END)                              AS defaulted_loans,
    SUM(CASE WHEN l.status = 'npl'
        THEN 1 ELSE 0 END)                              AS npl_loans,
    SUM(CASE WHEN l.status = 'settled'
        THEN 1 ELSE 0 END)                              AS settled_loans,
    ROUND(SUM(CASE WHEN l.status IN ('defaulted','npl')
              THEN 1 ELSE 0 END) /
          NULLIF(COUNT(l.loan_id), 0) * 100, 2)         AS default_rate_pct,
    FORMAT(SUM(CASE WHEN l.status IN ('defaulted','npl')
               THEN l.outstanding_balance ELSE 0 END), 2)
                                                        AS npl_exposure_myr
FROM branches b
LEFT JOIN loans l ON b.branch_id = l.branch_id
GROUP BY b.branch_id, b.branch_name, b.state
ORDER BY default_rate_pct DESC;

-- ============================================================
-- Q6: CREDIT CARD SPENDING BY MERCHANT CATEGORY
-- Business question: Where are customers spending on credit?
-- Useful for targeted rewards programme design.
-- ============================================================
SELECT
    ct.merchant_category,
    COUNT(*)                                            AS total_transactions,
    FORMAT(SUM(ct.amount), 2)                           AS total_spend_myr,
    FORMAT(AVG(ct.amount), 2)                           AS avg_spend_myr,
    FORMAT(MIN(ct.amount), 2)                           AS min_spend_myr,
    FORMAT(MAX(ct.amount), 2)                           AS max_spend_myr,
    ROUND(COUNT(*) /
          SUM(COUNT(*)) OVER () * 100, 2)               AS pct_of_transactions
FROM card_transactions ct
JOIN cards cd ON ct.card_id = cd.card_id
WHERE ct.status = 'approved'
  AND cd.card_type = 'credit'
GROUP BY ct.merchant_category
ORDER BY SUM(ct.amount) DESC;

-- ============================================================
-- Q7: BRANCH PERFORMANCE RANKING
-- Business question: Rank all branches on a composite KPI
-- covering deposits, loans, customers, and activity.
-- ============================================================
SELECT
    branch_name,
    state,
    total_customers,
    total_accounts,
    FORMAT(total_deposits, 2)                           AS total_deposits_myr,
    total_loans,
    FORMAT(total_loan_book, 2)                          AS total_loan_book_myr,
    FORMAT(total_outstanding, 2)                        AS total_outstanding_myr,
    COALESCE(ldr_pct, 0)                                AS ldr_pct,
    RANK() OVER (ORDER BY total_deposits DESC)          AS deposit_rank,
    RANK() OVER (ORDER BY total_customers DESC)         AS customer_rank,
    RANK() OVER (ORDER BY total_loans DESC)             AS loan_rank
FROM vw_branch_kpi
ORDER BY deposit_rank;

-- ============================================================
-- Q8: LOAN-TO-DEPOSIT RATIO (LDR) BY BRANCH
-- Business question: Is each branch lending too much or too
-- little relative to its deposit base?
-- BNM guideline: LDR should stay below 90%.
-- ============================================================
SELECT
    branch_name,
    state,
    FORMAT(total_deposits, 2)                           AS total_deposits_myr,
    FORMAT(total_outstanding, 2)                        AS loans_outstanding_myr,
    COALESCE(ldr_pct, 0)                                AS ldr_pct,
    CASE
        WHEN ldr_pct IS NULL     THEN 'No Loans'
        WHEN ldr_pct < 60        THEN 'Under-lent'
        WHEN ldr_pct BETWEEN 60
             AND 90              THEN 'Healthy'
        WHEN ldr_pct > 90        THEN 'Over-lent ⚠️'
    END                                                 AS ldr_status
FROM vw_branch_kpi
ORDER BY ldr_pct DESC;

-- ============================================================
-- Q9: CUSTOMER SEGMENTATION BY WEALTH TIER
-- Business question: Segment customers into wealth quartiles
-- using NTILE() for personalised product targeting.
-- ============================================================
SELECT
    customer_id,
    full_name,
    income_tier,
    monthly_income,
    total_balance,
    NTILE(4) OVER (ORDER BY total_balance DESC)         AS wealth_quartile,
    CASE NTILE(4) OVER (ORDER BY total_balance DESC)
        WHEN 1 THEN 'Premium'
        WHEN 2 THEN 'Affluent'
        WHEN 3 THEN 'Mass Market'
        WHEN 4 THEN 'Entry Level'
    END                                                 AS customer_segment
FROM (
    SELECT
        c.customer_id,
        c.full_name,
        c.income_tier,
        c.monthly_income,
        COALESCE(SUM(a.balance), 0)                     AS total_balance
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
                        AND a.status = 'active'
    GROUP BY c.customer_id, c.full_name,
             c.income_tier, c.monthly_income
) ranked
ORDER BY total_balance DESC;

-- ============================================================
-- Q10: RUNNING ACCOUNT BALANCE USING WINDOW FUNCTION
-- Business question: Show the cumulative transaction history
-- for a specific account (account_id = 1).
-- Demonstrates SUM() OVER with ORDER BY.
-- ============================================================
SELECT
    transaction_id,
    transaction_type,
    FORMAT(amount, 2)                                   AS amount_myr,
    channel,
    description,
    transaction_date,
    FORMAT(balance_after, 2)                            AS balance_after_myr,
    FORMAT(SUM(
        CASE
            WHEN transaction_type IN
                 ('deposit','transfer_in','interest')
            THEN amount
            ELSE -amount
        END
    ) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                               AS running_net_flow_myr,
    ROW_NUMBER() OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
    )                                                   AS txn_sequence
FROM transactions
WHERE account_id = 1
ORDER BY transaction_date;

-- ============================================================
-- Q11: CTE — CUSTOMER 360° PORTFOLIO VIEW
-- Business question: Provide a full financial snapshot per
-- customer combining accounts, loans, and cards in one view.
-- ============================================================
WITH cte_accounts AS (
    SELECT
        customer_id,
        COUNT(*)                                        AS num_accounts,
        ROUND(SUM(balance), 2)                          AS total_balance
    FROM accounts
    WHERE status = 'active'
    GROUP BY customer_id
),
cte_loans AS (
    SELECT
        customer_id,
        COUNT(*)                                        AS num_loans,
        ROUND(SUM(principal_amount), 2)                 AS total_borrowed,
        ROUND(SUM(outstanding_balance), 2)              AS total_outstanding,
        SUM(CASE WHEN status IN ('defaulted','npl')
            THEN 1 ELSE 0 END)                          AS bad_loans
    FROM loans
    GROUP BY customer_id
),
cte_cards AS (
    SELECT
        customer_id,
        COUNT(*)                                        AS num_cards,
        ROUND(SUM(COALESCE(credit_limit, 0)), 2)        AS total_credit_limit,
        ROUND(SUM(outstanding_balance), 2)              AS total_card_outstanding
    FROM cards
    WHERE status = 'active'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.full_name,
    c.income_tier,
    FORMAT(c.monthly_income, 2)                         AS monthly_income_myr,
    b.branch_name,
    -- Accounts
    COALESCE(a.num_accounts, 0)                         AS num_accounts,
    FORMAT(COALESCE(a.total_balance, 0), 2)             AS total_deposits_myr,
    -- Loans
    COALESCE(l.num_loans, 0)                            AS num_loans,
    FORMAT(COALESCE(l.total_borrowed, 0), 2)            AS total_borrowed_myr,
    FORMAT(COALESCE(l.total_outstanding, 0), 2)         AS outstanding_loans_myr,
    COALESCE(l.bad_loans, 0)                            AS bad_loans,
    -- Cards
    COALESCE(cd.num_cards, 0)                           AS num_cards,
    FORMAT(COALESCE(cd.total_credit_limit, 0), 2)       AS credit_limit_myr,
    FORMAT(COALESCE(cd.total_card_outstanding, 0), 2)   AS card_outstanding_myr,
    -- Net position
    FORMAT(
        COALESCE(a.total_balance, 0) -
        COALESCE(l.total_outstanding, 0) -
        COALESCE(cd.total_card_outstanding, 0), 2
    )                                                   AS net_financial_position_myr
FROM customers c
JOIN branches b             ON c.home_branch_id = b.branch_id
LEFT JOIN cte_accounts a    ON c.customer_id    = a.customer_id
LEFT JOIN cte_loans l       ON c.customer_id    = l.customer_id
LEFT JOIN cte_cards cd      ON c.customer_id    = cd.customer_id
ORDER BY COALESCE(a.total_balance, 0) DESC
LIMIT 20;

-- ============================================================
-- Q12: OVERDUE LOAN PAYMENT DETECTION
-- Business question: Which customers have missed or partial
-- repayments? Early warning system for credit teams.
-- ============================================================
SELECT
    full_name,
    loan_type,
    branch_name,
    income_tier,
    FORMAT(amount_due, 2)                               AS amount_due_myr,
    FORMAT(amount_paid, 2)                              AS amount_paid_myr,
    FORMAT(amount_due - amount_paid, 2)                 AS shortfall_myr,
    due_date,
    paid_date,
    repayment_status,
    days_overdue,
    CASE
        WHEN days_overdue > 90   THEN 'Serious Delinquency ⛔'
        WHEN days_overdue > 30   THEN 'Moderate Risk 🔴'
        WHEN days_overdue > 0    THEN 'Early Delinquency 🟡'
        ELSE 'Monitoring'
    END                                                 AS risk_flag
FROM vw_overdue_loans
ORDER BY days_overdue DESC;

-- ============================================================
-- Q13: MONTH-OVER-MONTH TRANSACTION GROWTH
-- Business question: Is transaction volume growing or
-- declining? Uses LAG() to compare with previous month.
-- ============================================================
WITH monthly_txn AS (
    SELECT
        DATE_FORMAT(transaction_date, '%Y-%m')          AS txn_month,
        COUNT(*)                                        AS txn_count,
        ROUND(SUM(amount), 2)                           AS total_amount
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
)
SELECT
    txn_month,
    txn_count,
    FORMAT(total_amount, 2)                             AS total_amount_myr,
    LAG(txn_count) OVER (ORDER BY txn_month)            AS prev_month_count,
    LAG(total_amount) OVER (ORDER BY txn_month)         AS prev_month_amount,
    ROUND(
        (txn_count - LAG(txn_count)
            OVER (ORDER BY txn_month)) /
        NULLIF(LAG(txn_count)
            OVER (ORDER BY txn_month), 0) * 100, 2
    )                                                   AS mom_count_growth_pct,
    ROUND(
        (total_amount - LAG(total_amount)
            OVER (ORDER BY txn_month)) /
        NULLIF(LAG(total_amount)
            OVER (ORDER BY txn_month), 0) * 100, 2
    )                                                   AS mom_value_growth_pct
FROM monthly_txn
ORDER BY txn_month;

-- ============================================================
-- Q14: CARD SPENDING PATTERN — TOP MERCHANTS BY CATEGORY
-- Business question: Who are the top 3 merchants in each
-- spending category? Uses RANK() with PARTITION BY.
-- ============================================================
WITH merchant_totals AS (
    SELECT
        merchant_category,
        merchant_name,
        COUNT(*)                                        AS txn_count,
        ROUND(SUM(amount), 2)                           AS total_spend,
        ROUND(AVG(amount), 2)                           AS avg_spend,
        RANK() OVER (
            PARTITION BY merchant_category
            ORDER BY SUM(amount) DESC
        )                                               AS spend_rank
    FROM card_transactions
    WHERE status = 'approved'
    GROUP BY merchant_category, merchant_name
)
SELECT
    merchant_category,
    spend_rank,
    merchant_name,
    txn_count,
    FORMAT(total_spend, 2)                              AS total_spend_myr,
    FORMAT(avg_spend, 2)                                AS avg_spend_myr
FROM merchant_totals
WHERE spend_rank <= 3
ORDER BY merchant_category, spend_rank;

-- ============================================================
-- BONUS: Test the stored procedure
-- Returns full portfolio for customer_id = 1
-- ============================================================
CALL GetCustomerPortfolio(1);
