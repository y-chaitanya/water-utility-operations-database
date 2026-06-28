/* ============================================================================
   05_post_refresh_validation.sql
   SCV Water Operations Database - Post-Refresh Validation Checklist
   ----------------------------------------------------------------------------
   Purpose : After a test/dev environment is refreshed from production (a restore
             or a data copy-down), confirm it is structurally sound and safe to
             use. Mirrors the "perform post-refresh validation activities" duty.
   Output  : Each check returns PASS, WARN, or FAIL with details. Review any
             FAIL/WARN row before handing the environment over.
   Run     : Execute against the refreshed database (e.g., SCV_Operations).
   ============================================================================ */

USE SCV_Operations;
GO
SET NOCOUNT ON;
PRINT '=========================================================';
PRINT ' POST-REFRESH VALIDATION - SCV_Operations';
PRINT ' Run time (UTC): ' + CONVERT(VARCHAR(30), SYSUTCDATETIME(), 120);
PRINT '=========================================================';
GO

/* ----------------------------------------------------------------------------
   Check 1: All expected tables are present
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 1: Expected tables present';
;WITH expected(name) AS (
    SELECT 'Customers' UNION ALL SELECT 'Meters' UNION ALL SELECT 'Usage_Readings'
    UNION ALL SELECT 'Billing' UNION ALL SELECT 'Audit_Log' UNION ALL SELECT 'System_Alerts'
)
SELECT e.name AS table_name,
       CASE WHEN t.object_id IS NULL THEN 'FAIL - MISSING' ELSE 'PASS' END AS result
FROM expected e
LEFT JOIN sys.tables t ON t.name = e.name
ORDER BY e.name;
GO

/* ----------------------------------------------------------------------------
   Check 2: Row counts per table (did data actually come across?)
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 2: Row counts (an empty critical table can mean a bad refresh)';
SELECT t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY t.name
ORDER BY t.name;
GO

/* ----------------------------------------------------------------------------
   Check 3: Foreign keys exist AND are trusted.
   After bulk loads or restores, FKs can be left "not trusted", which silently
   weakens their guarantees and hurts the query optimizer. We want zero untrusted.
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 3: Foreign keys present and trusted';
SELECT name AS foreign_key,
       OBJECT_NAME(parent_object_id) AS on_table,
       CASE WHEN is_not_trusted = 1 THEN 'FAIL - NOT TRUSTED' ELSE 'PASS' END AS result
FROM sys.foreign_keys
ORDER BY on_table, name;

-- Optional fix-up: re-trust all foreign keys after a load (uncomment to use)
-- EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

/* ----------------------------------------------------------------------------
   Check 4: No orphaned child rows (referential integrity holes)
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 4: Orphan detection (all should be 0)';
SELECT 'Meters without a Customer' AS check_name,
       COUNT(*) AS orphan_rows,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM Meters m LEFT JOIN Customers c ON m.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Usage_Readings without a Meter',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM Usage_Readings u LEFT JOIN Meters m ON u.meter_id = m.meter_id
WHERE m.meter_id IS NULL
UNION ALL
SELECT 'Billing without a Customer',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM Billing b LEFT JOIN Customers c ON b.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

/* ----------------------------------------------------------------------------
   Check 5: CHECK constraints are enabled and trusted (not disabled by a load)
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 5: CHECK constraints enabled and trusted';
SELECT name AS check_constraint,
       OBJECT_NAME(parent_object_id) AS on_table,
       CASE WHEN is_disabled   = 1 THEN 'FAIL - DISABLED'
            WHEN is_not_trusted = 1 THEN 'WARN - NOT TRUSTED'
            ELSE 'PASS' END AS result
FROM sys.check_constraints
ORDER BY on_table, name;
GO

/* ----------------------------------------------------------------------------
   Check 6: Expected security roles exist (access wasn't lost in the refresh)
   ---------------------------------------------------------------------------- */
PRINT '';
PRINT 'Check 6: Security roles present';
;WITH expected(name) AS (
    SELECT 'meter_reader' UNION ALL SELECT 'billing_clerk' UNION ALL SELECT 'ops_analyst'
)
SELECT e.name AS role_name,
       CASE WHEN dp.name IS NULL THEN 'WARN - MISSING (run 02_roles_and_privileges.sql)'
            ELSE 'PASS' END AS result
FROM expected e
LEFT JOIN sys.database_principals dp ON dp.name = e.name AND dp.type = 'R'
ORDER BY e.name;
GO

PRINT '';
PRINT 'Post-refresh validation complete. Review any FAIL/WARN rows above.';
GO
