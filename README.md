# SCV Water Operations Database — Learning Sandbox

A hands-on project where I will model a water-utility database
to learn database administration (DBA) concepts, mapped to the
SCV Water IT Specialist role.

> **Note:** This is an independent learning sandbox. All data is
> fictional and synthetically generated for practice — no real
> customer or agency data is used. This README is a living plan:
> each stage moves from *planned* to *done* as I build it.

---

## Why I'm Building This

I have a B.Tech in Computer Science and experience with web
application development. As I move into IT Specialist and systems
work, I want to go beyond writing application code and understand
the full lifecycle of data infrastructure: integrity, security,
and recovery.

My background as a licensed Enrolled Agent (EA) means I approach
data design with a compliance-first mindset — I believe a system
is only as trustworthy as its data integrity and its audit trail.

---

## The Data Model (Planned)

| Table | Purpose |
|-------|---------|
| `Customers` | Account holders and service addresses |
| `Meters` | Water meter status and link to customers |
| `Usage_Readings` | Time-series meter readings |
| `Billing` | Charges calculated from usage |
| `Audit_Log` | Traceability for data changes |
| `System_Alerts` | Operational monitoring alerts |

Tables will be linked with primary and foreign keys so the data
stays consistent.

---

## Build Stages

### Stage 1 — Schema & Data Integrity (DDL) — *Current*
Define the tables, primary/foreign keys, and constraints
(NOT NULL, CHECK, UNIQUE) so the data is clean and consistent.
*Concepts: normalization, keys, referential integrity.*

### Stage 2 — Security & Roles (DCL) — *Planned*
Create database roles and users with `GRANT`/`REVOKE`, applying
least privilege (each role gets only the access it needs).
*Concepts: roles vs users, GRANT/REVOKE, auditing.*

### Stage 3 — Backup & Recovery — *Planned*
Practice full and differential backups and a restore, and define
a simple recovery plan with RPO/RTO goals.
*Concepts: backup types, point-in-time recovery, RPO/RTO.*

### Stage 4 — Reporting & Scripts — *Planned*
Write queries and stored procedures for usage reports and tiered
billing using `JOIN`, `GROUP BY`, and `HAVING`.
*Concepts: joins, aggregation, views, stored procedures.*

---

## Planned Features

As the project grows, I plan to add:

- **Audit Log:** a trigger on the `Meters` table that records any
  status change to `Audit_Log` with a timestamp and the user —
  reflecting the compliance and internal-control thinking from my
  EA and CPA study.
- **Anomaly Alerts:** a trigger on `Usage_Readings` that flags an
  unusually high reading (a possible leak or meter fault) into
  `System_Alerts` for the operations team to review.

---

## Tools

- **Database:** SQL Server Express (in Docker on macOS)
- **Management:** Azure Data Studio
- **Language:** SQL (DDL, DCL, DML)

---

## Notes & Lessons (updated as I go)

I'll record what I learn at each stage here — what worked, what
was tricky, and what I'd do differently. The goal isn't just a
finished database; it's genuinely understanding the DBA concepts
behind it by building them hands-on.

---

*Work in progress. I'm building this to learn the database and
infrastructure skills required for public-sector systems work —
one stage at a time.*

*Maintainer: Chaitanya Yarlagadda*
