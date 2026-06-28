/* ============================================================================
   03_audit_and_alert_triggers.sql
   SCV Water Operations Database - Automatic Audit & Anomaly Triggers
   ----------------------------------------------------------------------------
   Purpose : Two AFTER triggers that fire automatically on data changes:
             (1) audit every meter status change for accountability/compliance;
             (2) raise an alert when a reading looks like a possible leak.
   Concept : A trigger is "when X happens, automatically do Y" - no app code and
             no human step required. Inside a trigger, 'inserted' holds the NEW
             row values and 'deleted' holds the PREVIOUS values.
   Run     : Execute AFTER 01_schema_setup.sql. Re-runnable.
   ============================================================================ */

USE SCV_Operations;
GO

DROP TRIGGER IF EXISTS trg_MeterStatusAudit;
GO
DROP TRIGGER IF EXISTS trg_HighReadingAlert;
GO

/* ----------------------------------------------------------------------------
   Trigger 1: audit every change to a meter's status.
   Written set-based so it correctly handles multi-row updates in one statement.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER trg_MeterStatusAudit
ON Meters
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit_Log (meter_id, old_status, new_status, changed_by)
    SELECT i.meter_id, d.status, i.status, SYSTEM_USER
    FROM inserted i
    JOIN deleted  d ON i.meter_id = d.meter_id
    WHERE i.status <> d.status;     -- only log when the status actually changed
END;
GO

/* ----------------------------------------------------------------------------
   Trigger 2: flag a reading that looks like a possible leak or meter fault.
   The flat threshold is a simple demo rule; a production system would compare
   each reading to that meter's own rolling average instead of a fixed number.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER trg_HighReadingAlert
ON Usage_Readings
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO System_Alerts (meter_id, reading_value, alert_type)
    SELECT i.meter_id, i.reading_value, 'HIGH_USAGE_POSSIBLE_LEAK'
    FROM inserted i
    WHERE i.reading_value > 50000;  -- demo threshold (gallons)
END;
GO

/* ============================================================================
   TEST THE TRIGGERS
   ============================================================================ */

PRINT '--- Test 1: change a meter status, then read the audit log ---';
UPDATE Meters SET status = 'Faulty' WHERE meter_number = 'MTR-003';
GO
SELECT meter_id, old_status, new_status, changed_by, changed_at FROM Audit_Log;
GO

PRINT '--- Test 2: insert an abnormally high reading, then read the alerts ---';
INSERT INTO Usage_Readings (meter_id, reading_value)
SELECT meter_id, 95000.00 FROM Meters WHERE meter_number = 'MTR-001';
GO
SELECT meter_id, reading_value, alert_type, raised_at, reviewed FROM System_Alerts;
GO

PRINT 'Triggers created and tested successfully.';
GO
