# 📂 2 · Security Layer — Roles & Least Privilege

This layer defines who can do what in the database, using **role-based access control** and the **principle of least privilege**: each role is granted only the access its job requires, and nothing more. Implemented in [`02_roles_and_privileges.sql`](02_roles_and_privileges.sql).

## What this layer does
- Creates three database roles that mirror real utility job functions.
- Grants each role the **minimum** rights it needs with `GRANT`, and demonstrates removing rights with `REVOKE`.
- Creates demo users (`WITHOUT LOGIN`, so they exist only inside this database) and adds them to roles.
- **Tests enforcement**: it switches into a restricted user with `EXECUTE AS`, confirms a permitted action succeeds, then attempts an action the user is *not* allowed to perform and shows the database blocking it — caught in a `TRY...CATCH` so the script proves the block rather than crashing.

> This is the difference between *documenting* security and *enforcing* it. The script doesn't just say a meter reader can't edit billing — it tries, and shows SQL Server refusing.

---

## 👤 Roles and granted access

| Role | Granted access | Real-world function |
| :-- | :-- | :-- |
| `meter_reader` | `SELECT` on `Customers`, `Meters`, `Usage_Readings` | Field staff who read meters — can look up assets and readings, cannot change financial data |
| `billing_clerk` | `SELECT` on `Customers`; `SELECT`, `INSERT`, `UPDATE` on `Billing` | Office staff who manage bills — can work with billing, cannot touch meter or usage records |
| `ops_analyst` | `SELECT`, `UPDATE` on `System_Alerts` | Operations staff who triage leak/anomaly alerts — can review and mark alerts handled |

### Demo users (for the enforcement test)
| User | Member of | Login |
| :-- | :-- | :-- |
| `demo_reader` | `meter_reader` | `WITHOUT LOGIN` (database-scoped, no server login) |
| `demo_biller` | `billing_clerk` | `WITHOUT LOGIN` (database-scoped, no server login) |

---

## 🔒 The enforcement test (what the screenshot shows)
1. `EXECUTE AS USER = 'demo_reader'` — act as a meter reader.
2. `SELECT` from `Meters` → **succeeds** (this role is allowed to read assets).
3. `UPDATE` on `Billing` → **blocked** by SQL Server; the permission error is caught and reported, proving the restriction holds.
4. `REVERT` — return to the normal user.

This confirms least privilege is actually applied: the role can do its job and is stopped from doing anything outside it.

---

## 🖥️ Run verification
![Least privilege verified](../Screenshots/05_security_layer_least_privilege_verified.png)

*Acting as a restricted role: the permitted read on the asset tables succeeds, while an attempted billing update is blocked by the database — least privilege enforced by the engine, not just written down.*
