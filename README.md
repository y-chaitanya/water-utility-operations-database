# 🌊 Water Utility Operations Database

**A working, end-to-end SQL Server project covering requirements, schema design, security, automation, recovery, monitoring, and performance tuning — modeled on water-utility operations.**

Not a tutorial copy and not a slide deck — a runnable database, documented from requirements through validation, with every piece executed and evidenced.

> ⚠️ **Sandbox note:** This is a local development environment. All schemas, tables, and records are fictional and synthetically generated for practice.

---

## 🎯 Why I built this

I'm returning to technology after a planned career break, and I wanted to *demonstrate* these skills rather than only claim them. So I defined the requirements, designed the system, built it in SQL Server, tested it, and documented the results. Everything here is something I can run, explain, and defend.

---

## 🚰 Domain context & design intent

The project models a regional water utility — customers, metered service connections, readings, billing, and service requests — so the schema and operations reflect a real operational domain rather than abstract examples.

**A note on scale (honest scoping):** This is a sandbox with synthetic sample data, *not* a production-scale dataset. The schema is **designed** with the relationships, keys, and data types a system would need to **scale** — the design fundamentals that keep queries efficient as data grows — but it has **not** been load-tested at volume.

**Why these layers:** A public water agency's priorities — reliability, data protection, and readiness for emergencies like droughts, fires, and earthquakes — map naturally onto core systems work:

- **Data protection & public trust** → role-based, least-privilege access (`2_security_layer/02`)
- **Business continuity** → backups and point-in-time restore, recovering data to the moment before a failure (`4_operations_layer/04`)
- **Early warning** → triggers that automatically flag abnormal readings — the pattern used to catch a leak or usage spike early (`3_automation_layer/03`)
- **Staying healthy as data grows** → capacity monitoring, index tuning, and scheduled maintenance (`4_operations_layer/06`–`09`)

The goal is to show these skills applied to a realistic operational context — honestly scoped as a demonstration, not a production deployment.

---

## 🗺️ What each layer demonstrates

**Data Layer** (`1_data_layer/01_schema_setup.sql`)
Functional requirements translated into a normalized six-table schema with primary/foreign keys and `NOT NULL` / `CHECK` / `UNIQUE` constraints enforcing data integrity at the engine level.
→ *Requirements definition · data modeling · integrity rules*

**Security Layer** (`2_security_layer/02_roles_and_privileges.sql`)
Security requirements specified and implemented as database roles with least-privilege `GRANT`/`REVOKE` — including a test confirming a restricted role is correctly blocked.
→ *Access control design · security specification · verification testing*

**Automation Layer** (`3_automation_layer/03_audit_and_alert_triggers.sql`)
Audit-trail and exception-alert logic: triggers that log meter status changes and flag abnormally high readings automatically.
→ *Audit trail design · exception handling · compliance logging*

**Operations Layer** (`4_operations_layer/04`–`09`)
Full / differential / log backups with point-in-time restore, a post-refresh validation checklist, capacity and performance monitoring, query tuning with indexing (before/after execution plans), and routine maintenance bundled into a logged, scheduled procedure.
→ *Business continuity planning · acceptance-style validation · performance measurement · operational documentation*

---

## 🏗️ How it's organized

```
water-utility-operations-database/
├── 1_data_layer/          → schema, keys, constraints, sample data
├── 2_security_layer/      → roles, users, least-privilege GRANT/REVOKE
├── 3_automation_layer/    → audit-log and anomaly-alert triggers
├── 4_operations_layer/    → backups + recovery, validation, monitoring, tuning, scheduled maintenance
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

**Query performance tuning — before and after**
![Index tuning before and after](Screenshots/10_index_tuning_before_after.png)
*The same query before and after adding an index: a full table scan becomes an index seek, with logical reads dropping sharply.*

**Automated maintenance ran on schedule**
![Maintenance log populated by the scheduler](Screenshots/11_maintenance_log_scheduled_runs.png)
*The maintenance log with rows added automatically by the scheduler minutes apart — proof the routine ran on its own, with no manual execution.*

---

## ⚙️ Tech stack

**SQL Server** (Express) · **T-SQL** (DDL / DML / DCL) · **Docker** on macOS · **Visual Studio Code** with the `mssql` extension

**Local setup:** Ran SQL Server in a Docker container with the database port mapped to the local host (`1433`) for client access via VS Code.

---

## ▶️ Run it yourself

Start a SQL Server container, then run in order:

1. `1_data_layer/01_schema_setup.sql` *(first — builds the database and sample data)*
2. `2_security_layer/02_roles_and_privileges.sql`
3. `3_automation_layer/03_audit_and_alert_triggers.sql`
4. `4_operations_layer/06_capacity_monitoring.sql` and `05_post_refresh_validation.sql`
5. `4_operations_layer/07_index_tuning_demo.sql` *(turn on the actual execution plan to see the scan → seek difference)*
6. `4_operations_layer/08_maintenance_procedure.sql`, then follow `4_operations_layer/09_scheduling_setup.md` to schedule it

`4_operations_layer/04_backup_and_recovery.sql` is a self-contained recovery demonstration that intentionally alters data — run it on its own, then re-run `01_schema_setup.sql` for pristine data. Create the backup folder once with `docker exec <container> mkdir -p /var/opt/mssql/backup`.

> **Note on scheduling:** SQL Server Express has no SQL Server Agent, so the maintenance procedure is scheduled with cron inside the container (see `09_scheduling_setup.md`). On Standard/Enterprise the same procedure would run as a one-line SQL Agent job — the skill is identical, only the scheduler differs.

---

## 📌 About

Built as part of a deliberate, hands-on return to technology — requirements through validation, documented end to end. A focused sandbox with synthetic data, and still growing.
