# 📂 4 · Operations Layer — Recovery, Validation & Monitoring

This layer covers the ongoing care of the database: protecting data with backups and recovery, verifying a database after a refresh, watching capacity and performance, tuning query performance, and automating routine maintenance.

| Script | Purpose |
| :-- | :-- |
| [`04_backup_and_recovery.sql`](04_backup_and_recovery.sql) | Backups and point-in-time recovery |
| [`05_post_refresh_validation.sql`](05_post_refresh_validation.sql) | Health checks after an environment refresh |
| [`06_capacity_monitoring.sql`](06_capacity_monitoring.sql) | Capacity planning and performance checks |
| [`07_index_tuning_demo.sql`](07_index_tuning_demo.sql) | Query performance tuning with an index (before/after) |
| [`08_maintenance_procedure.sql`](08_maintenance_procedure.sql) | Routine maintenance bundled into a callable procedure |
| [`09_scheduling_setup.md`](09_scheduling_setup.md) | Automating that maintenance on a schedule (Express-appropriate method) |

---

## 💾 `04_backup_and_recovery.sql` — Backups & Recovery

### What it does
- Sets the database to the **`FULL` recovery model** so transaction-log backups (and point-in-time recovery) are possible.
- Takes the three backup types and explains when each is used:

| Backup type | What it captures | Typical use |
| :-- | :-- | :-- |
| **Full** | The entire database | Baseline restore point |
| **Differential** | Everything changed since the last full | Faster than a full; smaller |
| **Transaction log** | Every change since the last log backup | Enables recovery to a *specific moment* |

- Demonstrates **point-in-time recovery**: it restores to a separate copy database (`SCV_Operations_Copy`) and uses `STOPAT` to recover the data to the moment **just before a simulated bad change**, leaving the original untouched.

### Framing it as RPO / RTO
- **RPO (Recovery Point Objective)** — how much data you can afford to lose. Frequent log backups shrink the RPO.
- **RTO (Recovery Time Objective)** — how quickly you must be back. A full + differential strategy shortens restore time and the RTO.

> **Run this one on its own.** It intentionally alters data to demonstrate recovery. After running it, re-run `1_data_layer/01_schema_setup.sql` to return to pristine sample data. Create the backup folder once with:
> `docker exec <container> mkdir -p /var/opt/mssql/backup`
> (Paths use the Linux container layout `/var/opt/mssql/backup`.)

---

## ✅ `05_post_refresh_validation.sql` — Post-Refresh Validation

### What it does
After a database is refreshed or restored (for example, copying production into a test environment), this script runs a checklist and reports **PASS / WARN / FAIL** for each item, so you can confirm the environment is sound before anyone uses it:

- All expected tables are present.
- Tables contain data (row counts are non-zero where expected).
- **Foreign keys are trusted** — no constraints left in an un-validated state after a bulk load.
- No orphaned rows (every child row still points to a valid parent).
- `CHECK` constraints are trusted.
- Expected roles exist.

This turns "did the refresh work?" into a repeatable, evidence-producing check instead of a guess.

---

## 📈 `06_capacity_monitoring.sql` — Capacity & Performance

### What it does
Reports the routine health metrics a DBA watches to stay ahead of capacity and performance problems:

- **Data and log file sizes**, free space inside each file, and **autogrowth** settings.
- **Transaction-log space usage** — a key thing to watch under the `FULL` recovery model.
- **Per-table size and row counts** — where the data actually lives.
- **Index inventory** and index-usage statistics.
- **Most expensive queries** pulled from SQL Server's dynamic management views (DMVs).

Together these answer "are we running out of room?" and "what's slow, and why?" before they become outages.

---

## 🚀 `07_index_tuning_demo.sql` — Query Performance Tuning

### What it does
A **before-and-after** demonstration of fixing a slow query with an index — the core of performance tuning:

1. **Seeds extra synthetic readings** so the performance difference is measurable (with only a few rows, the engine scans regardless).
2. **Before:** runs a typical "get one meter's recent readings" query and captures the cost — the execution plan shows a **table scan** (reads the whole table) with high logical reads.
3. **Adds a non-clustered index** on `(meter_id, read_at)` that also covers the query.
4. **After:** runs the *same* query — the plan now shows an **index seek** and far fewer reads. Same answer, far less work.
5. **Missing-index hints:** queries the DMVs SQL Server uses to record indexes it "wishes existed" — how a DBA decides what to tune, instead of guessing.
6. **Fragmentation check:** reports index fragmentation with a REORGANIZE / REBUILD recommendation.

Runs natively in SQL Server Express — indexing needs no paid edition.

---

## ⚙️ `08_maintenance_procedure.sql` + `09_scheduling_setup.md` — Automated Maintenance

### What it does
Bundles routine maintenance into one callable stored procedure (`usp_RunMaintenance`) and schedules it to run automatically:

- **The procedure** reorganizes fragmented indexes (only when fragmentation warrants it), updates statistics so the optimizer keeps choosing good plans, records a capacity snapshot (row counts), and writes every action to a `Maintenance_Log` table.
- **The scheduling** ([`09_scheduling_setup.md`](09_scheduling_setup.md)) runs that procedure on a timer.

### ⚠️ Honest note on the scheduling method
SQL Server **Express edition has no SQL Server Agent** (the usual job scheduler). So instead of scheduling raw SQL the standard way, this wraps the work in a stored procedure and calls it on a schedule using **cron inside the Linux container** with `sqlcmd`. The skill demonstrated — automating a recurring maintenance task — is the same; only the scheduler differs. **On Standard/Enterprise, the identical procedure would be scheduled with a one-line SQL Agent job** (`EXEC dbo.usp_RunMaintenance`).

The `Maintenance_Log` table is the proof: rows appear on their own every few minutes, with timestamps, confirming the schedule actually fired — the same "prove it ran" discipline as the rest of the project.

---

## 🖥️ Run verification

**Point-in-time recovery**
![Point-in-time recovery](../Screenshots/07_point_in_time_recovery_proof.png)
*A copy of the database restored to the moment just before a simulated bad change, recovering the correct data while the original is left intact.*

**Post-refresh validation**
![Post-refresh validation](../Screenshots/08_post_refresh_validation_checklist.png)
*The validation checklist returning PASS across the environment-integrity checks.*

**Capacity & performance**
![Capacity and performance](../Screenshots/09.1_capacity_headroom_and_performance.png)
*File and log space, autogrowth settings, and index usage — the routine capacity and performance checks behind keeping the database healthy.*

**Index tuning — before and after**
![Index tuning before and after](../Screenshots/10_index_tuning_before_after.png)
*The same query before and after adding the index: a full table scan becomes an index seek, with logical reads dropping sharply — the tuning win.*

**Automated maintenance ran on schedule**
![Maintenance log populated by the scheduler](../Screenshots/11_maintenance_log_scheduled_runs.png)
*The `Maintenance_Log` table with rows added automatically by the scheduler a few minutes apart — proof the maintenance ran on its own, with no manual execution.*

> 📷 **Screenshot filenames:** the two new captions point to `10_index_tuning_before_after.png` and `11_maintenance_log_scheduled_runs.png`. Save your new screenshots under those names in the `Screenshots/` folder (or rename to match your numbering) so they render on GitHub.
