/* ============================================================================
   02_roles_and_privileges.sql
   SCV Water Operations Database - Roles, Users & Least Privilege
   ----------------------------------------------------------------------------
   Purpose : Demonstrate role-based access control (RBAC) and the principle of
             least privilege - each role is granted only the access its job
             requires, and nothing more.
   Note    : Users are created WITHOUT LOGIN purely so permissions can be tested
             inside this single database with EXECUTE AS, without configuring
             server-level logins. In production these map to real logins / AD.
   Run     : Execute AFTER 01_schema_setup.sql. Re-runnable.
   ============================================================================ */

USE SCV_Operations;
GO

/* Clean up so the script is re-runnable */
IF DATABASE_PRINCIPAL_ID('demo_reader')   IS NOT NULL DROP USER demo_reader;
IF DATABASE_PRINCIPAL_ID('demo_biller')   IS NOT NULL DROP USER demo_biller;
IF DATABASE_PRINCIPAL_ID('meter_reader')  IS NOT NULL DROP ROLE meter_reader;
IF DATABASE_PRINCIPAL_ID('billing_clerk') IS NOT NULL DROP ROLE billing_clerk;
IF DATABASE_PRINCIPAL_ID('ops_analyst')   IS NOT NULL DROP ROLE ops_analyst;
GO

/* ----------------------------------------------------------------------------
   1) Create roles (each role is a job "badge")
   ---------------------------------------------------------------------------- */
CREATE ROLE meter_reader;    -- field staff: read meters and readings only
CREATE ROLE billing_clerk;   -- billing staff: work with billing records
CREATE ROLE ops_analyst;     -- operations: review system alerts
GO

/* ----------------------------------------------------------------------------
   2) Grant each role ONLY what its job needs (least privilege)
   ---------------------------------------------------------------------------- */
-- Meter readers may look up customers, meters and readings, but not change them
GRANT SELECT ON Customers      TO meter_reader;
GRANT SELECT ON Meters         TO meter_reader;
GRANT SELECT ON Usage_Readings TO meter_reader;

-- Billing clerks may read and maintain billing, and read who they are billing
GRANT SELECT               ON Customers TO billing_clerk;
GRANT SELECT, INSERT, UPDATE ON Billing TO billing_clerk;

-- Operations analysts review and clear alerts
GRANT SELECT, UPDATE ON System_Alerts TO ops_analyst;
GO

/* ----------------------------------------------------------------------------
   3) Create users and assign them to roles (give staff their badge)
   ---------------------------------------------------------------------------- */
CREATE USER demo_reader WITHOUT LOGIN;
CREATE USER demo_biller WITHOUT LOGIN;

ALTER ROLE meter_reader  ADD MEMBER demo_reader;
ALTER ROLE billing_clerk ADD MEMBER demo_biller;
GO

/* ----------------------------------------------------------------------------
   4) Prove least privilege works.
   EXECUTE AS USER switches the security context; REVERT switches it back.
   ---------------------------------------------------------------------------- */
PRINT '--- demo_reader can SELECT meters (allowed) ---';
EXECUTE AS USER = 'demo_reader';
    SELECT TOP 3 meter_number, status FROM Meters;   -- succeeds
REVERT;
GO

PRINT '--- demo_reader attempts to change billing (should FAIL) ---';
BEGIN TRY
    EXECUTE AS USER = 'demo_reader';
        UPDATE Billing SET paid = 1 WHERE bill_id = 1;   -- no permission granted
    REVERT;
END TRY
BEGIN CATCH
    REVERT;  -- always restore context, even on error
    PRINT 'Blocked as expected: ' + ERROR_MESSAGE();
END CATCH;
GO

/* ----------------------------------------------------------------------------
   5) Revoke access (e.g., when someone changes roles or leaves)
   ---------------------------------------------------------------------------- */
-- Example: remove the clerk role's ability to insert new billing rows
REVOKE INSERT ON Billing FROM billing_clerk;
-- Example: remove a member from a role
ALTER ROLE meter_reader DROP MEMBER demo_reader;
GO

PRINT 'Security roles, users, and least-privilege checks completed.';
GO
