# SCV Water Operations Database — Learning Project

A hands-on database project where I'm learning database
administration concepts by building a water-utility
operations database in SQL/Oracle.

I built this to deepen my DBA skills — schema design,
security, backup/recovery, and reporting — mapped to the
SCV Water IT Specialist role.

> **Note:** This is an independent learning sandbox. All
> data is fictional and synthetically generated for
> practice — no real customer or agency data is used.

---

## What This Project Is

A relational database modeling a water utility's core
operations: customers, meters, usage readings, and billing.
I'm building it in stages, learning one area of database
administration at a time.

I have a Computer Science engineering foundation and SQL
query experience. This project is where I'm genuinely
building the database administration side — the install,
security, backup, and maintenance concepts — hands-on.

---

## The Data Model

| Table | Purpose |
|-------|---------|
| Customers | Account holders served by the utility |
| Meters | Water meters linked to customers |
| Usage_Readings | Meter readings over time |
| Billing | Charges calculated from usage |

Tables are linked with primary and foreign keys so the
data stays consistent.

---

## Build Stages

### Stage 1 — Schema & Data Integrity (DDL)
Designing the tables, keys, and constraints (NOT NULL,
CHECK, UNIQUE) so the data is clean and consistent.
*Concepts: normalization, primary/foreign keys,
referential integrity.*

### Stage 2 — Security & Roles (DCL) — *in progress*
Creating database roles and users with GRANT and REVOKE,
following least-privilege (each role only gets the access
it needs).
*Concepts: roles vs users, GRANT/REVOKE, auditing.*

### Stage 3 — Backup & Recovery — *planned*
Practicing backups and a restore, and writing a simple
recovery plan for if the database goes down.
*Concepts: full vs incremental backup, point-in-time
recovery, RPO/RTO.*

### Stage 4 — Reporting & Scripts — *planned*
Writing queries for usage reports and tiered billing using
JOIN, GROUP BY, and HAVING.
*Concepts: joins, aggregation, views, stored procedures.*

---

## Tools

- **Database:** Oracle XE / SQL Server Express (free editions)
- **Language:** SQL (DDL, DCL, DML)

---

## Why I'm Building This

I learn best by building. Rather than only reading about
database administration, I'm setting up a real database and
working through each concept hands-on — the same way I
learn any new area.

*Maintainer: Chaitanya Yarlagadda*
