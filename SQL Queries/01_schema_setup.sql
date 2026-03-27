-- ============================================================
-- FILE: 01_schema_setup.sql
-- PROJECT: Malaysian Banking & Fintech Analytics (Synthetic)
-- AUTHOR: Aritra Paul
-- DESCRIPTION: Full database schema — 8 tables, PKs, FKs,
--              indexes, 4 views, 1 stored procedure.
--              Data is 100% synthetic (fictional).
--              Inspired by Malaysian retail banking context.
-- ENGINE: MySQL 8.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS mybank_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mybank_analytics;

-- ============================================================
-- TABLE 1: branches
-- 10 fictional branches across Malaysian states
-- ============================================================
CREATE TABLE IF NOT EXISTS branches (
    branch_id       INT             NOT NULL AUTO_INCREMENT,
    branch_name     VARCHAR(100)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    state           VARCHAR(50)     NOT NULL,
    address         VARCHAR(255)    NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    manager_name    VARCHAR(100)    NOT NULL,
    opened_date     DATE            NOT NULL,
    CONSTRAINT pk_branches
        PRIMARY KEY (branch_id)
);

-- ============================================================
-- TABLE 2: customers
-- 80 fictional Malaysian customers
-- NRIC format: YYMMDD-SS-NNNN (synthetic, non-real)
-- income_tier: B40 / M40 / T20 (Malaysian income classification)
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id         INT             NOT NULL AUTO_INCREMENT,
    nric                VARCHAR(14)     NOT NULL,
    full_name           VARCHAR(100)    NOT NULL,
    gender              ENUM('M','F')   NOT NULL,
    date_of_birth       DATE            NOT NULL,
    phone               VARCHAR(20)     NOT NULL,
    email               VARCHAR(100)    NOT NULL,
    address             VARCHAR(255)    NOT NULL,
    state               VARCHAR(50)     NOT NULL,
    occupation          VARCHAR(100)    NOT NULL,
    monthly_income      DECIMAL(10,2)   NOT NULL,
    income_tier         ENUM('B40','M40','T20') NOT NULL,
    home_branch_id      INT             NOT NULL,
    customer_since      DATE            NOT NULL,
    CONSTRAINT pk_customers
        PRIMARY KEY (customer_id),
    CONSTRAINT uq_nric
        UNIQUE (nric),
    CONSTRAINT uq_email
        UNIQUE (email),
    CONSTRAINT fk_customers_branch
        FOREIGN KEY (home_branch_id)
        REFERENCES branches(branch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_income
        CHECK (monthly_income > 0)
);

-- ============================================================
-- TABLE 3: accounts
-- 120 accounts — savings, current, fixed deposit
-- account_number format: MY-XXXXXX-XX (synthetic)
-- maturity_date: only applicable for fixed deposit accounts
-- ============================================================
CREATE TABLE IF NOT EXISTS accounts (
    account_id      INT             NOT NULL AUTO_INCREMENT,
    customer_id     INT             NOT NULL,
    branch_id       INT             NOT NULL,
    account_number  VARCHAR(20)     NOT NULL,
    account_type    ENUM('savings','current','fixed_deposit') NOT NULL,
    balance         DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
    interest_rate   DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    status          ENUM('active','dormant','closed')         NOT NULL DEFAULT 'active',
    opened_date     DATE            NOT NULL,
    maturity_date   DATE            NULL,
    CONSTRAINT pk_accounts
        PRIMARY KEY (account_id),
    CONSTRAINT uq_account_number
        UNIQUE (account_number),
    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_accounts_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_balance
        CHECK (balance >= 0)
);

-- ============================================================
-- TABLE 4: transactions
-- 600+ banking transactions
-- channel: ATM / online / counter / mobile
-- type: deposit / withdrawal / transfer_in / transfer_out / payment / interest
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id      INT             NOT NULL AUTO_INCREMENT,
    account_id          INT             NOT NULL,
    transaction_type    ENUM('deposit','withdrawal','transfer_in',
                             'transfer_out','payment','interest')  NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    balance_after       DECIMAL(15,2)   NOT NULL,
    transaction_date    DATETIME        NOT NULL,
    channel             ENUM('ATM','online','counter','mobile')    NOT NULL,
    description         VARCHAR(255)    NOT NULL,
    reference_no        VARCHAR(30)     NOT NULL,
    CONSTRAINT pk_transactions
        PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_amount
        CHECK (amount > 0)
);

-- ============================================================
-- TABLE 5: loans
-- 50 synthetic loans
-- type: personal / home / car / sme
-- status: active / settled / defaulted / npl (non-performing)
-- ============================================================
CREATE TABLE IF NOT EXISTS loans (
    loan_id                 INT             NOT NULL AUTO_INCREMENT,
    customer_id             INT             NOT NULL,
    branch_id               INT             NOT NULL,
    loan_type               ENUM('personal','home','car','sme')    NOT NULL,
    principal_amount        DECIMAL(12,2)   NOT NULL,
    outstanding_balance     DECIMAL(12,2)   NOT NULL,
    interest_rate           DECIMAL(5,2)    NOT NULL,
    tenure_months           INT             NOT NULL,
    monthly_instalment      DECIMAL(10,2)   NOT NULL,
    disbursement_date       DATE            NOT NULL,
    maturity_date           DATE            NOT NULL,
    status                  ENUM('active','settled','defaulted','npl') NOT NULL DEFAULT 'active',
    CONSTRAINT pk_loans
        PRIMARY KEY (loan_id),
    CONSTRAINT fk_loans_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_loans_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_principal
        CHECK (principal_amount > 0),
    CONSTRAINT chk_tenure
        CHECK (tenure_months > 0)
);

-- ============================================================
-- TABLE 6: loan_repayments
-- Monthly instalment records per loan
-- status: paid / partial / missed / pending
-- ============================================================
CREATE TABLE IF NOT EXISTS loan_repayments (
    repayment_id    INT             NOT NULL AUTO_INCREMENT,
    loan_id         INT             NOT NULL,
    due_date        DATE            NOT NULL,
    paid_date       DATE            NULL,
    amount_due      DECIMAL(10,2)   NOT NULL,
    amount_paid     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    status          ENUM('paid','partial','missed','pending')  NOT NULL DEFAULT 'pending',
    CONSTRAINT pk_repayments
        PRIMARY KEY (repayment_id),
    CONSTRAINT fk_repayments_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================================
-- TABLE 7: cards
-- 70 debit and credit cards
-- credit_limit: NULL for debit cards
-- card_number_last4: last 4 digits only (security best practice)
-- ============================================================
CREATE TABLE IF NOT EXISTS cards (
    card_id             INT             NOT NULL AUTO_INCREMENT,
    customer_id         INT             NOT NULL,
    account_id          INT             NOT NULL,
    card_type           ENUM('debit','credit')              NOT NULL,
    card_network        ENUM('Visa','Mastercard')           NOT NULL,
    card_number_last4   CHAR(4)                             NOT NULL,
    credit_limit        DECIMAL(10,2)   NULL,
    outstanding_balance DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    status              ENUM('active','blocked','expired')  NOT NULL DEFAULT 'active',
    issued_date         DATE            NOT NULL,
    expiry_date         DATE            NOT NULL,
    CONSTRAINT pk_cards
        PRIMARY KEY (card_id),
    CONSTRAINT fk_cards_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_cards_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================================
-- TABLE 8: card_transactions
-- 400+ card spending records
-- merchant_category: groceries / dining / travel / online /
--                    utilities / entertainment / petrol / healthcare
-- ============================================================
CREATE TABLE IF NOT EXISTS card_transactions (
    card_txn_id         INT             NOT NULL AUTO_INCREMENT,
    card_id             INT             NOT NULL,
    merchant_name       VARCHAR(100)    NOT NULL,
    merchant_category   ENUM('groceries','dining','travel','online',
                             'utilities','entertainment','petrol',
                             'healthcare')                  NOT NULL,
    amount              DECIMAL(10,2)   NOT NULL,
    transaction_date    DATETIME        NOT NULL,
    status              ENUM('approved','declined','reversed') NOT NULL DEFAULT 'approved',
    CONSTRAINT pk_card_transactions
        PRIMARY KEY (card_txn_id),
    CONSTRAINT fk_card_txn_card
        FOREIGN KEY (card_id)
        REFERENCES cards(card_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_card_txn_amount
        CHECK (amount > 0)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_customers_state          ON customers(state);
CREATE INDEX idx_customers_income_tier    ON customers(income_tier);
CREATE INDEX idx_customers_branch         ON customers(home_branch_id);
CREATE INDEX idx_accounts_customer        ON accounts(customer_id);
CREATE INDEX idx_accounts_type            ON accounts(account_type);
CREATE INDEX idx_accounts_status          ON accounts(status);
CREATE INDEX idx_transactions_account     ON transactions(account_id);
CREATE INDEX idx_transactions_date        ON transactions(transaction_date);
CREATE INDEX idx_transactions_type        ON transactions(transaction_type);
CREATE INDEX idx_loans_customer           ON loans(customer_id);
CREATE INDEX idx_loans_type               ON loans(loan_type);
CREATE INDEX idx_loans_status             ON loans(status);
CREATE INDEX idx_repayments_loan          ON loan_repayments(loan_id);
CREATE INDEX idx_repayments_status        ON loan_repayments(status);
CREATE INDEX idx_repayments_due_date      ON loan_repayments(due_date);
CREATE INDEX idx_cards_customer           ON cards(customer_id);
CREATE INDEX idx_card_txn_card            ON card_transactions(card_id);
CREATE INDEX idx_card_txn_date            ON card_transactions(transaction_date);
CREATE INDEX idx_card_txn_category        ON card_transactions(merchant_category);

-- ============================================================
-- VIEW 1: vw_account_summary
-- Flat view joining accounts with customer and branch details.
-- ============================================================
CREATE OR REPLACE VIEW vw_account_summary AS
SELECT
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance,
    a.interest_rate,
    a.status                                        AS account_status,
    a.opened_date,
    c.customer_id,
    c.full_name,
    c.income_tier,
    c.monthly_income,
    b.branch_name,
    b.state                                         AS branch_state
FROM accounts a
JOIN customers c    ON a.customer_id    = c.customer_id
JOIN branches b     ON a.branch_id      = b.branch_id;

-- ============================================================
-- VIEW 2: vw_loan_portfolio
-- Loan details with customer demographics and branch.
-- Includes days overdue calculation.
-- ============================================================
CREATE OR REPLACE VIEW vw_loan_portfolio AS
SELECT
    l.loan_id,
    l.loan_type,
    l.principal_amount,
    l.outstanding_balance,
    l.interest_rate,
    l.tenure_months,
    l.monthly_instalment,
    l.disbursement_date,
    l.maturity_date,
    l.status                                        AS loan_status,
    c.customer_id,
    c.full_name,
    c.income_tier,
    c.monthly_income,
    ROUND(l.monthly_instalment /
          NULLIF(c.monthly_income, 0) * 100, 2)     AS dsr_pct,
    b.branch_name,
    b.state                                         AS branch_state
FROM loans l
JOIN customers c    ON l.customer_id    = c.customer_id
JOIN branches b     ON l.branch_id      = b.branch_id;

-- ============================================================
-- VIEW 3: vw_branch_kpi
-- Aggregated branch-level KPIs for performance benchmarking.
-- ============================================================
CREATE OR REPLACE VIEW vw_branch_kpi AS
SELECT
    b.branch_id,
    b.branch_name,
    b.state,
    COUNT(DISTINCT c.customer_id)                   AS total_customers,
    COUNT(DISTINCT a.account_id)                    AS total_accounts,
    ROUND(SUM(CASE WHEN a.status = 'active'
              THEN a.balance ELSE 0 END), 2)        AS total_deposits,
    COUNT(DISTINCT l.loan_id)                       AS total_loans,
    ROUND(SUM(l.principal_amount), 2)               AS total_loan_book,
    ROUND(SUM(l.outstanding_balance), 2)            AS total_outstanding,
    ROUND(SUM(l.outstanding_balance) /
          NULLIF(SUM(CASE WHEN a.status = 'active'
                     THEN a.balance ELSE 0 END), 0)
          * 100, 2)                                 AS ldr_pct
FROM branches b
LEFT JOIN customers c   ON b.branch_id  = c.home_branch_id
LEFT JOIN accounts a    ON c.customer_id = a.customer_id
LEFT JOIN loans l       ON c.customer_id = l.customer_id
GROUP BY b.branch_id, b.branch_name, b.state;

-- ============================================================
-- VIEW 4: vw_overdue_loans
-- Flags loan repayments that are missed or overdue.
-- Used in Q12 delinquency analysis.
-- ============================================================
CREATE OR REPLACE VIEW vw_overdue_loans AS
SELECT
    lr.repayment_id,
    lr.loan_id,
    l.loan_type,
    c.full_name,
    c.income_tier,
    b.branch_name,
    lr.due_date,
    lr.paid_date,
    lr.amount_due,
    lr.amount_paid,
    lr.status                                       AS repayment_status,
    DATEDIFF(CURDATE(), lr.due_date)                AS days_overdue
FROM loan_repayments lr
JOIN loans l        ON lr.loan_id       = l.loan_id
JOIN customers c    ON l.customer_id    = c.customer_id
JOIN branches b     ON l.branch_id      = b.branch_id
WHERE lr.status IN ('missed', 'partial')
  AND lr.due_date < CURDATE();

-- ============================================================
-- STORED PROCEDURE: GetCustomerPortfolio
-- Returns full financial portfolio for a given customer_id.
-- Shows accounts, total loans, cards in one call.
-- Usage: CALL GetCustomerPortfolio(1);
-- ============================================================
DELIMITER //

CREATE PROCEDURE GetCustomerPortfolio(
    IN p_customer_id INT
)
BEGIN
    -- Customer profile
    SELECT
        c.customer_id,
        c.full_name,
        c.nric,
        c.income_tier,
        c.monthly_income,
        c.customer_since,
        b.branch_name                               AS home_branch
    FROM customers c
    JOIN branches b ON c.home_branch_id = b.branch_id
    WHERE c.customer_id = p_customer_id;

    -- Accounts
    SELECT
        account_number,
        account_type,
        ROUND(balance, 2)                           AS balance,
        status
    FROM accounts
    WHERE customer_id = p_customer_id
      AND status = 'active';

    -- Loans
    SELECT
        loan_type,
        ROUND(principal_amount, 2)                  AS principal,
        ROUND(outstanding_balance, 2)               AS outstanding,
        ROUND(monthly_instalment, 2)                AS monthly_instalment,
        maturity_date,
        status
    FROM loans
    WHERE customer_id = p_customer_id;

    -- Cards
    SELECT
        card_type,
        card_network,
        CONCAT('****', card_number_last4)           AS card_number,
        credit_limit,
        ROUND(outstanding_balance, 2)               AS outstanding_balance,
        status,
        expiry_date
    FROM cards
    WHERE customer_id = p_customer_id
      AND status = 'active';
END //

DELIMITER ;
