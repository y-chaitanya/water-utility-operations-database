# 🛡️ Security Layer: Role-Based Access Control (RBAC)

This directory houses the access control policies for the database environment, implementing the core industry standard of **Least Privilege**.

## 🌊 The Story
In an enterprise environment, a field technician reading water meters should not have access to financial credit card ledgers, and an office billing clerk should not have the authority to wipe out physical engineering machinery statuses. This layer creates distinct digital security badges (Roles) and programs the data doors to ensure personnel only access information explicitly required to execute their job functions.

## 🛠️ What This Layer Controls
* **Database Roles Defined**: `meter_reader` (field staff), `billing_clerk` (finance/office staff), and `ops_analyst` (systems monitoring).
* **Granular Permissions**: Restricts field staff to read-only paths while granting write/modification powers on financial tables strictly to authorized billing roles.
* **Security Context Drills**: Features an automated testing routine (`EXECUTE AS USER`) that deliberately simulates a security breach attempt to verify that the server forcefully blocks unauthorized operations.

---

## 📸 Production Verification
The access verification routines demonstrate that a field operator can successfully interact with asset tables while unauthorized write operations are actively deflected by the engine security policy.

![Security Access Validation](../Screenshots/05_security_layer_least_privilege_verified.png)