# 📂 1 · Data Layer — Schema & Data Definition (DDL)

This layer creates the database and its core tables, with data integrity enforced **at the engine level**. Implemented in [`01_schema_setup.sql`](01_schema_setup.sql) using SQL Server T-SQL.

> **Engine note:** This project runs on **Microsoft SQL Server**, so column types are `VARCHAR`, `DECIMAL`, `DATETIME2`, and `BIT`, with `IDENTITY` surrogate keys and `SYSUTCDATETIME()` defaults. (On Oracle these would map to `VARCHAR2`, `NUMBER`, `TIMESTAMP`, and `SYSDATE`.)

## What this layer does
- Creates the `SCV_Operations` database (only if it does not already exist) and six related tables.
- Enforces integrity with explicit `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `CHECK`, and `UNIQUE` constraints — so invalid or orphaned data is rejected by the database itself, even if an application has a bug.
- Loads synthetic sample data so the security, automation, and operations layers have something to run against.
- Is re-runnable: it drops the tables in reverse dependency order and recreates them each time.

---

## 📋 Data Dictionary

### `Customers` — utility account holders
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `customer_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated unique customer ID |
| `account_number` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Business account number; no two customers share one |
| `first_name` | `VARCHAR(50)` | `NOT NULL` | Account holder first name |
| `last_name` | `VARCHAR(50)` | `NOT NULL` | Account holder last name |
| `service_address` | `VARCHAR(200)` | `NOT NULL` | Physical service location |
| `email` | `VARCHAR(100)` | Optional (`NULL`) | Contact email |
| `created_at` | `DATETIME2` | `NOT NULL`, `DEFAULT SYSUTCDATETIME()` | Record creation timestamp (UTC) |

### `Meters` — physical water meters
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `meter_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated unique meter ID |
| `meter_number` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Asset/serial number of the meter |
| `customer_id` | `INT` | `NOT NULL`, `FOREIGN KEY → Customers` | Owning customer |
| `meter_size_inches` | `DECIMAL(4,2)` | `NOT NULL`, `CHECK (> 0)` | Meter size; must be positive |
| `status` | `VARCHAR(20)` | `NOT NULL`, `DEFAULT 'Active'`, `CHECK` | One of `Active`, `Inactive`, `Removed`, `Faulty` |
| `installed_on` | `DATE` | `NOT NULL` | Installation date |

### `Usage_Readings` — consumption per meter
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `reading_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated unique reading ID |
| `meter_id` | `INT` | `NOT NULL`, `FOREIGN KEY → Meters` | Meter the reading belongs to |
| `reading_value` | `DECIMAL(12,2)` | `NOT NULL`, `CHECK (>= 0)` | Consumption (gallons); never negative |
| `read_at` | `DATETIME2` | `NOT NULL`, `DEFAULT SYSUTCDATETIME()` | When the reading was taken (UTC) |
| *(table)* | — | `UNIQUE (meter_id, read_at)` | Prevents duplicate reads for one meter at the same time |

### `Billing` — charges per customer per period
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `bill_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated unique bill ID |
| `customer_id` | `INT` | `NOT NULL`, `FOREIGN KEY → Customers` | Customer being billed |
| `billing_period_start` | `DATE` | `NOT NULL` | Start of billing period |
| `billing_period_end` | `DATE` | `NOT NULL` | End of billing period |
| `amount_due` | `DECIMAL(10,2)` | `NOT NULL`, `CHECK (>= 0)` | Amount owed; non-negative |
| `paid` | `BIT` | `NOT NULL`, `DEFAULT 0` | Paid flag (0 = unpaid, 1 = paid) |
| *(table)* | — | `CHECK (end >= start)` | Period end cannot precede start |

### `Audit_Log` — automatic history of meter status changes
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `audit_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated audit entry ID |
| `meter_id` | `INT` | `NOT NULL` | Meter whose status changed (no FK by design — see note) |
| `old_status` | `VARCHAR(20)` | `NULL` | Status before the change |
| `new_status` | `VARCHAR(20)` | `NOT NULL` | Status after the change |
| `changed_by` | `SYSNAME` | `NOT NULL` | Database user who made the change |
| `changed_at` | `DATETIME2` | `NOT NULL`, `DEFAULT SYSUTCDATETIME()` | When the change occurred (UTC) |

> Written automatically by a trigger (see `3_automation_layer/`). Audit tables intentionally omit a foreign key so an audit write is never blocked by a lock or a delete on the source row.

### `System_Alerts` — automatic anomaly / leak alerts
| Column | Data Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| `alert_id` | `INT` | `IDENTITY`, `PRIMARY KEY` | Auto-generated alert ID |
| `meter_id` | `INT` | `NOT NULL` | Meter that triggered the alert |
| `reading_value` | `DECIMAL(12,2)` | `NOT NULL` | The reading that raised the alert |
| `alert_type` | `VARCHAR(50)` | `NOT NULL` | Alert category (e.g., `HIGH_USAGE_POSSIBLE_LEAK`) |
| `raised_at` | `DATETIME2` | `NOT NULL`, `DEFAULT SYSUTCDATETIME()` | When the alert was raised (UTC) |
| `reviewed` | `BIT` | `NOT NULL`, `DEFAULT 0` | Whether operations has reviewed it |

---

## 🔗 Relationships
```
Customers ──< Meters ──< Usage_Readings
     └──< Billing
```
`Audit_Log` and `System_Alerts` are populated automatically by triggers in the automation layer.

---

## 🖥️ Run verification
![Schema initialization](../Screenshots/04_schema_initialization_success.png)

*The schema script running on a live SQL Server container — all six tables created and synthetic sample data loaded successfully.*
