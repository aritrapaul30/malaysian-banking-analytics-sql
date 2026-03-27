# 🏦 Malaysian Banking Analytics: A Synthetic SQL Project

> A self-initiated, end-to-end SQL project, database designed, data
> generated, and business analysis performed entirely from scratch.
> No external datasets. No CSV imports. Pure SQL.

---

## 🧾 Project Overview

| Detail | Value |
|---|---|
| 🏛️ Simulated Entity | `mybank_analytics` - Fictional Malaysian Retail Bank |
| 🛠️ Tool | MySQL 8.0 Workbench |
| 📁 SQL Files | 3 structured files |
| 🗃️ Total Tables | 8 relational tables |
| 📊 Synthetic Rows | ~1,650+ rows generated manually |
| 🔍 Business Queries | 14 analysis queries + 1 bonus stored procedure |
| 👤 Author | Aritra Paul |

---

## 📁 Repository Structure

---

## 🗃️ Database Schema - 8 Tables

| Table | Purpose | Rows |
|---|---|---|
| `branches` | 10 fictional bank branches across Malaysia | 10 |
| `customers` | 80 fictional Malaysian customers (B40/M40/T20) | 80 |
| `accounts` | Savings, current & fixed deposit accounts | 120+ |
| `transactions` | Banking transaction records | 600+ |
| `loans` | Personal, home, car & SME loans | 50 |
| `loan_repayments` | Monthly instalment payment records | 150 |
| `cards` | Debit & credit card records | 70 |
| `card_transactions` | Merchant spending records | 200+ |

---

## 🔧 Advanced SQL Features Used

| Feature | Applied In |
|---|---|
| ⚙️ **Window Functions** | `RANK()`, `NTILE()`, `LAG()`, `SUM() OVER()` |
| 🔗 **CTEs** | Customer 360 portfolio view (Q11) |
| 🛡️ **Stored Procedure** | `GetCustomerPortfolio(customer_id)` - multi-result-set |
| 👁️ **Views** | 4 pre-computed analytical views |
| 🔒 **Constraints** | `CHECK`, `UNIQUE`, `ENUM`, `FK` with `ON DELETE RESTRICT` |
| 📐 **Indexes** | 19 indexes across frequently queried columns |
| ➗ **Safe Division** | `NULLIF` to prevent division-by-zero in LDR calculations |

---

## 📊 Key Business Findings

### 🏢 Branch Performance
- **Johor Bahru** holds the largest deposit base: **MYR 2,260,600** across 30 accounts
- **KLCC (KL)** follows at MYR 1,618,600 - together covering **~62% of total bank deposits**
- 3 East Malaysian branches (Kuching, Kota Kinabalu, Melaka) show **zero activity** - untapped market territory

---

### 🚨 Loan-to-Deposit Ratio - Critical Risk Finding

> ⚠️ Every active branch exceeds Bank Negara Malaysia's (BNM) recommended LDR ceiling of **90%**

| Branch | LDR (%) | Status |
|---|---|---|
| Subang Jaya | **438.26%** | 🔴 Over-lent |
| Georgetown | **363.76%** | 🔴 Over-lent |
| Johor Bahru | **281.58%** | 🔴 Over-lent |
| Petaling Jaya | **218.98%** | 🔴 Over-lent |
| KLCC | **205.54%** | 🔴 Over-lent |
| Shah Alam | **123.80%** | 🔴 Over-lent |
| Ipoh | **92.22%** | 🔴 Over-lent |

---

### 💰 Loan Portfolio
- **Home loans** dominate: MYR 6.43M total principal, 87.53% outstanding ratio
- **Personal loans** carry the highest rate: **7.96% avg** (unsecured)
- **SME loans**: highest secured rate at **5.80% avg**
- **Car loans**: most affordable at **3.12% avg**

---

### 👥 Customer Wealth Segmentation (`NTILE(4)`)

| Segment | Balance Range | Profile |
|---|---|---|
| 💎 Premium (Q1) | MYR 145K – 320K | All T20 + 2 M40 outliers |
| 🥇 Affluent (Q2) | MYR 90.5K – 143.5K | Mixed T20 & M40 |
| 🥈 Mass Market (Q3) | Mid-range | Salaried professionals |
| 🥉 Entry Level (Q4) | Below MYR 30K | Younger / lower-income earners |

> 💡 Two M40 customers appear in the Premium segment - proving savings
> behaviour matters more than income tier alone.

---

### ⚠️ Delinquency Detection
- **17 loan accounts** flagged in serious delinquency (>90 days overdue)
- Overdue range: **843 to 1,808 days**
- Most overdue: **Loh Thim Fook** - partial home loan payment unresolved for **1,808 days**
- Largest shortfall: **Azlina Mansor** - MYR 9,266.56 outstanding on SME loan
- Disproportionately affects **M40-tier borrowers**

---

### 💳 Card Spending Insights

| Category | Insight |
|---|---|
| ✈️ Travel | Highest avg spend per transaction: **MYR 627.29** (MAS, AirAsia) |
| 🛒 Groceries | Most frequent: **20.41%** of all transactions (Jaya Grocer, AEON, Tesco) |
| 🛍️ Online Shopping | Shopee MY alone: **MYR 5,078** total spend |
| 🏥 Healthcare | Lowest frequency but **MYR 214.50** avg (Pantai Hospital, KPJ) |

---

## 💡 Recommendations

**Immediate Actions:**
- 🚨 Launch deposit mobilisation campaigns - especially at Subang Jaya (438% LDR)
- ⚖️ Tighten loan approval controls across all 7 active branches
- 📋 Escalate 17 delinquent accounts for NPL classification & credit remediation

**Growth Opportunities:**
- 💎 Cross-sell fixed deposits, unit trusts & private banking to the Premium segment
- ✈️ Launch a co-branded travel credit card with Malaysia Airlines or AirAsia
- 🌏 Activate the 3 dormant East Malaysian branches (Kuching, KK, Melaka)

---

## 🛠️ Tech Stack

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![MySQL Workbench](https://img.shields.io/badge/MySQL_Workbench-00758F?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)

---

## 👤 Author

**Aritra Paul**
Master of Business Analytics - Sunway University
🔗 [LinkedIn](https://linkedin.com/in/aritrapaul30) · [GitHub](https://github.com/aritrapaul30)
