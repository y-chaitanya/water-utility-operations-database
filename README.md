# 🌊 SCV Water Operations Database — DBA Sandbox

**A working, end-to-end SQL Server database administration project, built to mirror the day-to-day duties of the SCV Water Information Technology Specialist role.**

Not a tutorial copy and not a slide deck — a runnable database with schema, security, automation, recovery, and monitoring, all modeled on water-utility operations and mapped directly to the job description.

> ⚠️ **Sandbox note:** This is a local development environment. All schemas, tables, and records are fictional and synthetically generated for practice.

---

## 🎯 Why I built this
I'm returning to technology after a planned career break, and I wanted to *demonstrate* the skills this role calls for rather than only claim them. So I built the database the posting describes — from the ground up in SQL Server — and ran every piece. Everything here is something I can run, explain, and defend.

---

## 🗺️ What this demonstrates — mapped to the job duties

| Script | What it demonstrates | SCV Water duty it maps to |
|--------|----------------------|----------------------------|
| `01_schema_setup` | Normalized schema, primary/foreign keys, `NOT NULL` / `CHECK` / `UNIQUE` constraints | Installs and maintains SQL data servers; sets up keys and enforces constraints |
| `02_roles_and_privileges` | Role-based access control, least privilege, `GRANT`/`REVOKE`, **tested** permissions | Manages user accounts, roles, and privileges; performs access audits |
| `03_audit_and_alert_triggers` | Event-driven audit logging and anomaly (leak) alerting | Develops, validates, and deploys scripts for database operations |
| `04_backup_and_recovery` | Full / differential / log backups, RPO/RTO, point-in-time restore | Performs backups; develops recovery plans; restores after outages |
| `05_post_refresh_validation` | Structural, integrity, and security checks after an environment refresh | Coordinates environment refreshes; performs post-refresh validation |
| `06_capacity_monitoring` | File/log growth, capacity planning, performance health | Monitors transaction logs and growth; responds to performance issues |

---

## 🏗️ How it's organized

```
scv-utility-database-administration/
├── 1_data_layer/          → schema, keys, constraints, sample data
├── 2_security_layer/      → roles, users, least-privilege GRANT/REVOKE
├── 3_automation_layer/    → audit-log and anomaly-alert triggers
├── 4_operations_layer/    → backups + recovery, post-refresh validation, monitoring
└── Screenshots/           → screenshots of the scripts running on the live environment
```

Each layer folder has its own README with a data dictionary and details.

---

## 🖥️ Proof it runs
Each stage was executed on the live SQL Server container. The screenshots below show the results (the full set is in the `Screenshots/` folder).

**Schema build**
![Schema initialization](Screenshots/04_schema_initialization_success.png)
*The schema script running on the live container — tables created and synthetic sample data loaded.*

**Least privilege enforced**
![Least privilege verified](Screenshots/05_security_layer_least_privilege_verified.png)
*A restricted role is correctly blocked from an action it isn't permitted to perform — access is enforced by the engine, not just documented.*

**Triggers fire automatically**
![Automated audit and leak detection](Screenshots/06_database_automation_leak_detection_success.png)
*A meter status change is logged to the audit table and an abnormally high reading raises a leak alert — automatically, with no application code.*

**Point-in-time recovery**
![Point-in-time recovery](Screenshots/07_point_in_time_recovery_proof.png)
*A copy of the database restored to the moment just before a simulated bad change, recovering the correct data.*

**Post-refresh validation**
![Post-refresh validation](Screenshots/08_post_refresh_validation_checklist.png)
*The validation checklist returning PASS across the environment-integrity checks.*

**Capacity & performance**
![Capacity and performance](Screenshots/09.1_capacity_headroom_and_performance.png)
*File and log space, autogrowth settings, and index usage — the routine checks behind capacity planning.*

---

## ⚙️ Tech stack
**SQL Server** (Express) · **T-SQL** (DDL / DML / DCL) · **Docker** on macOS · **Visual Studio Code** with the `mssql` extension
**Local setup**: Ran SQL Server in a Docker container with the database port mapped to the local host (1433) for client access via VS Code.

---

## ▶️ Run it yourself
Start a SQL Server container, then run in order:
1. `1_data_layer/01_schema_setup.sql` *(first — builds the database and sample data)*
2. `2_security_layer/02_roles_and_privileges.sql`
3. `3_automation_layer/03_audit_and_alert_triggers.sql`
4. `4_operations_layer/06_capacity_monitoring.sql` and `05_post_refresh_validation.sql`

`4_operations_layer/04_backup_and_recovery.sql` is a self-contained recovery demonstration that intentionally alters data — run it on its own, then re-run `01_schema_setup.sql` for pristine data. Create the backup folder once with `docker exec <container> mkdir -p /var/opt/mssql/backup`.

---

## 📌 About
Built as part of a deliberate, hands-on return to technology, to demonstrate the specific database administration skills this role requires. A focused sandbox with synthetic data — and still growing.
