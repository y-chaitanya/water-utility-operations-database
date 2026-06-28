/* ============================================================================
   04_backup_and_recovery.sql
   SCV Water Operations Database - Backup & Point-in-Time Recovery
   ----------------------------------------------------------------------------
   Purpose : Demonstrate a full / differential / transaction-log backup strategy
             and a point-in-time restore (the core of any recovery plan).
   Concepts: RPO (how much data you can afford to lose) drives backup frequency;
             RTO (how fast you must be back online) drives restore strategy.
   Story   : Take a full backup, do some good work, capture a "known-good" time,
             then simulate a MISTAKE. We recover a copy of the database to the
             moment just BEFORE the mistake.
   Paths   : Paths below are for SQL Server in a Linux container (Docker on
             macOS). Create the backup folder once:
                 docker exec <container> mkdir -p /var/opt/mssql/backup
             On Windows, change paths to e.g. C:\SQLBackups\ .
   Safety  : The restore targets a SEPARATE copy database (SCV_Operations_Copy),
             so your working database is never destroyed.
   Heads-up: This script intentionally alters data in SCV_Operations to tell the
             recovery story. Re-run 01_schema_setup.sql afterward for pristine data.
   Run     : Execute AFTER 01_schema_setup.sql.
   ============================================================================ */

USE master;
GO

-- Point-in-time recovery requires the FULL recovery model so the transaction
-- log records every change between backups.
ALTER DATABASE SCV_Operations SET RECOVERY FULL;
GO

/* ----------------------------------------------------------------------------
   1) FULL backup - a complete copy of the database (the full reservoir)
   ---------------------------------------------------------------------------- */
BACKUP DATABASE SCV_Operations
    TO DISK = '/var/opt/mssql/backup/SCV_full.bak'
    WITH INIT, NAME = 'SCV_Operations-Full', STATS = 10;
GO

/* ----------------------------------------------------------------------------
   2) Good activity, then capture a "known-good" moment in time.
      A temp table (#) persists across batches within this same session, so we
      can reuse the captured time in the RESTORE step further down.
   ---------------------------------------------------------------------------- */
USE SCV_Operations;
GO
IF OBJECT_ID('tempdb..#recovery_point') IS NOT NULL DROP TABLE #recovery_point;
CREATE TABLE #recovery_point (good_time DATETIME2);

INSERT INTO Usage_Readings (meter_id, reading_value)
SELECT meter_id, 1500.00 FROM Meters WHERE meter_number = 'MTR-001';

WAITFOR DELAY '00:00:02';                       -- small gap around the marker
INSERT INTO #recovery_point VALUES (SYSUTCDATETIME());
WAITFOR DELAY '00:00:02';
PRINT 'Known-good time captured.';
GO

/* ----------------------------------------------------------------------------
   3) A DIFFERENTIAL backup is also part of a normal rotation (only what changed
      since the last full). Shown here for completeness.
   ---------------------------------------------------------------------------- */
BACKUP DATABASE SCV_Operations
    TO DISK = '/var/opt/mssql/backup/SCV_diff.bak'
    WITH INIT, DIFFERENTIAL, NAME = 'SCV_Operations-Diff', STATS = 10;
GO

/* ----------------------------------------------------------------------------
   4) Simulate a MISTAKE that happens AFTER the known-good moment.
      (A bad mass update that wipes real consumption values.)
   ---------------------------------------------------------------------------- */
UPDATE Usage_Readings SET reading_value = 0;    -- oops
PRINT 'Mistake applied to the working database.';
GO

/* ----------------------------------------------------------------------------
   5) TRANSACTION LOG backup - the logbook of every change since the full
      backup; it contains BOTH the good activity and the mistake.
   ---------------------------------------------------------------------------- */
BACKUP LOG SCV_Operations
    TO DISK = '/var/opt/mssql/backup/SCV_log.trn'
    WITH INIT, NAME = 'SCV_Operations-Log', STATS = 10;
GO

/* ============================================================================
   6) POINT-IN-TIME RESTORE to a safe copy, stopping just BEFORE the mistake.
   ----------------------------------------------------------------------------
   Restore the full backup with NORECOVERY, then replay the log only up to our
   known-good time. Logical file names for a database created with
   CREATE DATABASE default to '<name>' (data) and '<name>_log' (log).
   ============================================================================ */
USE master;
GO
RESTORE DATABASE SCV_Operations_Copy
    FROM DISK = '/var/opt/mssql/backup/SCV_full.bak'
    WITH MOVE 'SCV_Operations'     TO '/var/opt/mssql/data/SCV_Operations_Copy.mdf',
         MOVE 'SCV_Operations_log' TO '/var/opt/mssql/data/SCV_Operations_Copy_log.ldf',
         NORECOVERY, REPLACE;
GO

DECLARE @stop DATETIME2 = (SELECT good_time FROM #recovery_point);
RESTORE LOG SCV_Operations_Copy
    FROM DISK = '/var/opt/mssql/backup/SCV_log.trn'
    WITH STOPAT = @stop, RECOVERY;             -- stop replay before the mistake
GO

/* ----------------------------------------------------------------------------
   7) Verify: the working DB has the zeros (mistake), the recovered copy doesn't.
   ---------------------------------------------------------------------------- */
SELECT 'Working DB (after mistake)' AS source,
       COUNT(*) AS rows_with_zero_value
FROM SCV_Operations.dbo.Usage_Readings WHERE reading_value = 0
UNION ALL
SELECT 'Restored copy (recovered)',
       COUNT(*)
FROM SCV_Operations_Copy.dbo.Usage_Readings WHERE reading_value = 0;
GO

PRINT 'Point-in-time recovery demo complete. The copy excludes the bad change.';
GO
