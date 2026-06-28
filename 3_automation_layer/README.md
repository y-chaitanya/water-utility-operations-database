# 🧠 Automation Layer: Real-Time Auditing & Anomaly Detection

This folder contains the automated event-driven programming modules responsible for self-monitoring database actions.

## 🌊 The Story
Instead of relying on human operators to scan spreadsheets or manual application code to track modifications, we install automated internal database sensors called **Triggers**. These work like digital dominoes: the exact millisecond an anomaly occurs or a critical piece of hardware changes state, the database catches it, logs it, and sounds the alarm completely independently.

## 🛠️ What This Layer Controls
* **`trg_MeterStatusAudit`**: An accountability trigger that watches the equipment registry. The moment a meter is flipped to a new status (e.g., from 'Active' to 'Faulty'), it intercepts the change and records a permanent, unalterable ledger trail tracking who performed the action and when.
* **`trg_HighReadingAlert`**: A near-real-time safety sensor that checks water usage data as it streams in. If a consumption event breaks a safety threshold (50,000+ gallons), it automatically logs an immediate `HIGH_USAGE_POSSIBLE_LEAK` emergency ticket.

---

## 📸 Production Verification
Live execution proves that manual parameter updates automatically cascade into immediate, secondary system responses within the validation ledger.

![Automation Validation Success](../Screenshots/06_database_automation_action_success.png)