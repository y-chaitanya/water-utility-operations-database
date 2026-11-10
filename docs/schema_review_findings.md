# Schema Review Findings

An independent-style review of my own schema (`01_schema_setup.sql`) for completeness, consistency and traceability. Each finding states what I checked, what I found, and a recommended fix.

| # | Area | Finding | Recommendation |
|---|---|---|---|
| 1 | Traceability | A bill's `amount_due` cannot be traced to the readings or rates behind it: `Billing` links to `Customers` only, and there is no rate table. | Add a `Rates` table and a `Billing_Lines` table linking each bill to the meter, readings and rate used. |
| 2 | Uniqueness | Nothing prevents two bills for the same customer and period. | Add `UNIQUE (customer_id, billing_period_start)`. |
| 3 | Historical data | Meter status can become `Removed`, but there is no removal date, so history depends on `Audit_Log` only. | Add `removed_on DATE NULL` with a CHECK that it is set when status is `Removed`. |
| 4 | Referential integrity | `System_Alerts.meter_id` has no foreign key. The no-FK choice is explained for `Audit_Log`, but `System_Alerts` relies on the same reason without stating it. | Document the decision for both tables, and add a periodic orphan check query. |
| 5 | Sample data completeness | Customer `ACC-1003` has May 2025 readings but no May 2025 bill. | Confirm whether this is intentional (for example, a test of unbilled usage) and note it, or add the bill. |
| 6 | Time zone consistency | Defaults use UTC (`SYSUTCDATETIME()`), but sample `read_at` values are entered without a time zone, so it is unclear whether they are UTC or local time. | State the time zone rule in the data dictionary and convert sample data to match. |
