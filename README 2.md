# SCV Water Operations Database Sandbox

A relational database sandbox modeling local water-utility operations. It contains the schema, security configuration, automation, recovery, and monitoring scripts used to manage utility data, enforce access controls, recover from failures, and track system health — built and runnable end to end.

> ⚠️ **Note:** This is a local sandbox environment. All schemas, tables, and data records are fictional and generated for development purposes.

---

## 📁 Project Directory Structure

```
scv-utility-database-administration/
├── README.md                               # Project documentation and operational guide
├── 1_data_layer/
│   └── 01_schema_setup.sql                 # Tables, primary/foreign keys, validation constraints, sample data
├── 2_security_layer/
│   └── 02_roles_and_privileges.sql         # Roles, users, least-privilege GRANT/REVOKE, permission test
├── 3_automation_layer/
│   └── 03_audit_and_alert_triggers.sql     # Audit-log and anomaly-alert triggers
└── 4_operations_layer/
    ├── 04_backup_and_recovery.sql          # Full / differential / log backups + point-in-time restore
    ├── 05_post_refresh_validation.sql      # Post-refresh environment verification checklist
    └── 06_capacity_monitoring.sql          # Space utilization, log growth, and performance checks
```

---

## 🗺️ Skills → SCV Water Duties

| Script | Demonstrates | Maps to duty |
|--------|--------------|--------------|
| `01_schema_setup` | Normalized schema, PK/FK, `NOT NULL`/`CHECK`/`UNIQUE` constraints | Installs/maintains SQL data servers; sets up keys and constraints |
| `02_roles_and_privileges` | RBAC, least privilege, `GRANT`/`REVOKE`, tested permissions | Manages user accounts, roles, and privileges; audits access |
| `03_audit_and_alert_triggers` | Event-driven audit logging and anomaly alerting | Develops, validates, and deploys scripts for database operations |
| `04_backup_and_recovery` | Full/diff/log backups, RPO/RTO, point-in-time restore | Performs backups; develops recovery plans; restores after outages |
| `05_post_refresh_validation` | Structural, integrity, and security verification after a refresh | Coordinates environment refreshes; performs post-refresh validation |
| `06_capacity_monitoring` | File/log growth, capacity planning, performance health | Monitors transaction logs and growth; responds to performance issues |

---

## 🏗️ Architecture & Components

### 🔹 Data Layer — Schema & Data Integrity
Core utility tables — `Customers`, `Meters`, `Usage_Readings`, `Billing`, `Audit_Log`, `System_Alerts` — with referential integrity and validation enforced **at the engine level** through explicit `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `CHECK`, and `UNIQUE` constraints.

### 🔹 Security Layer — Roles & Least Privilege
Database roles and users configured with `GRANT`/`REVOKE` under the principle of least privilege — each role receives only the access it needs. The script also **proves enforcement** by attempting a blocked action and catching the error.
*   *Meter Reader (Operations):* read access to meters and consumption data.
*   *Billing Clerk:* read/maintain billing; read customer profiles.
*   *Operations Analyst / Auditor:* review system alerts; read-only verification.

### 🔹 Automation Layer — Triggers
1. **Audit Log Trigger (`Meters`):** records every status change into `Audit_Log` with a timestamp and the executing system user — a compliance-first design reflecting an Enrolled Agent (EA) credential and internal-control background.
2. **Anomaly Alerts Trigger (`Usage_Readings`):** flags unusually high readings (possible leak or meter fault) into `System_Alerts` for immediate operations review.

### 🔹 Operations Layer — Recovery, Validation & Monitoring
*   **Backup & Recovery:** full, differential, and transaction-log backups, with a worked **point-in-time restore** that recovers a copy of the database to the moment just before a simulated error. The recovery plan is framed around explicit **RPO** and **RTO** goals.
*   **Post-Refresh Validation:** after copying production data down to a test environment, verifies tables, row counts, trusted foreign keys, orphaned rows, enabled constraints, and security roles.
*   **Capacity & Performance Monitoring:** tracks data file (`.mdf`) and log file (`.ldf`) growth for proactive capacity planning, and includes indexing and expensive-query checks.

---

## 💻 Environment & Tools
*   **Database Engine:** SQL Server Express running inside an isolated Docker container on macOS.
*   **IDE:** Visual Studio Code using the native `mssql` extension, connected via local port `1433`.
*   **Language:** T-SQL (Transact-SQL) — DDL (definition), DML (manipulation), and DCL (control).

---

## ▶️ Running the Project
Run in order against a running SQL Server container:
1. `1_data_layer/01_schema_setup.sql` *(first — builds the database and sample data)*
2. `2_security_layer/02_roles_and_privileges.sql`
3. `3_automation_layer/03_audit_and_alert_triggers.sql`
4. `4_operations_layer/06_capacity_monitoring.sql` and `05_post_refresh_validation.sql`

`4_operations_layer/04_backup_and_recovery.sql` is a self-contained demonstration that intentionally alters data to show recovery — run it on its own, then re-run `01_schema_setup.sql` for pristine data. Create the backup folder once with:
```bash
docker exec <container> mkdir -p /var/opt/mssql/backup
```

---

## 📌 About This Project
Built as part of a deliberate, hands-on return to technology, to demonstrate the specific database administration skills this role calls for. It is a focused sandbox with synthetic data, and it continues to grow.
