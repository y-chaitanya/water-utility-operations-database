# 📂 Schema Setup & Data Definition Language (DDL)

This directory contains the foundational database schemas, table definitions, data types, and structural integrity constraints required to initialize the public utility relational database framework.

---

## 📋 Active Database Data Dictionary

### 1. `meter_accounts` Table
Tracks individual customer accounts mapped to physical water utility meters.

| Column Name | Data Type | Constraints / Attributes | Description |
| :--- | :--- | :--- | :--- |
| `account_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Automatically generated unique sequential account identifier. |
| `customer_name` | `VARCHAR2(100)` | `NOT NULL` | Full name of the utility account holder. |
| `service_address` | `VARCHAR2(255)` | `NOT NULL` | Physical property location of the water service meter. |
| `phone_number` | `VARCHAR2(15)` | Optional | Account contact phone information. |
| `account_status` | `VARCHAR2(10)` | `DEFAULT 'ACTIVE'` | Operational status (`ACTIVE`, `SUSPENDED`, `CLOSED`). |
| `connection_date` | `DATE` | `DEFAULT SYSDATE` | System timestamp tracking initial service activation. |
