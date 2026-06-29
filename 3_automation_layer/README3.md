# 📂 3 · Automation Layer — Audit & Alert Triggers

This layer makes the database react **on its own** to important events — logging changes and flagging anomalies — with no application code involved. Implemented as two `AFTER` triggers in [`03_audit_and_alert_triggers.sql`](03_audit_and_alert_triggers.sql).

## What this layer does
- Adds an **audit trail**: whenever a meter's status changes, the database records who changed it, from what to what, and when.
- Adds **anomaly detection**: whenever a reading comes in above a threshold, the database raises a possible-leak alert automatically.
- Both run inside the database, so they fire no matter how the change arrives — app, script, or manual query.

> Triggers like these are how a database enforces compliance logging and early warnings consistently, instead of hoping every application remembers to do it.

---

## ⚡ Triggers

| Trigger | Fires on | Action | Writes to |
| :-- | :-- | :-- | :-- |
| `trg_MeterStatusAudit` | `AFTER UPDATE` on `Meters` | If `status` changed, record old value, new value, the user, and the time | `Audit_Log` |
| `trg_HighReadingAlert` | `AFTER INSERT` on `Usage_Readings` | If `reading_value` exceeds the threshold, raise a `HIGH_USAGE_POSSIBLE_LEAK` alert | `System_Alerts` |

---

## 🧠 Design notes
- **Set-based, not row-by-row.** Each trigger reads SQL Server's `inserted` and `deleted` virtual tables, so it correctly handles a statement that updates or inserts **many rows at once**, not just one.
- **Audit only on real change.** `trg_MeterStatusAudit` compares `inserted.status` to `deleted.status` and logs only when the value actually changed — an update that leaves status the same writes nothing.
- **Threshold is a demo constant.** The leak threshold (`> 50000`) is a fixed value chosen for demonstration. In a real deployment this would be configuration-driven or based on each meter's normal baseline, not a hard-coded number.
- **Captured user.** `changed_by` uses the database session user, so the audit reflects who actually performed the change.

---

## 🔬 Built-in tests (what the screenshot shows)
1. **Audit:** `UPDATE Meters SET status = 'Faulty'` for one meter → a new row appears in `Audit_Log` showing the old and new status, the user, and the timestamp.
2. **Alert:** `INSERT` an abnormally high reading (e.g., `95000`) for a meter → a new row appears in `System_Alerts` flagging a possible leak.

Both happen automatically as a side effect of the normal `UPDATE`/`INSERT` — no extra step is run to create the log or the alert.

---

## 🖥️ Run verification
![Automated audit and leak detection](../Screenshots/06_database_automation_leak_detection_success.png)

*A meter status change is written to the audit log and an abnormally high reading raises a leak alert — both produced automatically by the triggers, with no application code.*
