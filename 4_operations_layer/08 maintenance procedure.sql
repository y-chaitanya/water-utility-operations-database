/* ============================================================================
   08_maintenance_procedure.sql
   PURPOSE: Bundle routine DBA maintenance into one stored procedure that can
            be run on a schedule. This is the "task" that gets automated.

   Maps to SCV Water duty: "develops and configures database management tools"
   and "monitors growth ... ensures database maintenance."

   RUNS IN: SQL Server Express (Docker). Stored procedures are fully supported.

   WHY A STORED PROCEDURE:
   Express edition has NO SQL Server Agent (the usual job scheduler). So instead
   of scheduling raw SQL, we wrap the maintenance work in ONE callable procedure.
   Then a scheduler outside the database (cron, in the container) calls this
   procedure on a timer. Same outcome as a SQL Agent job — a recurring,
   automated maintenance task — using tools that exist in Express.

   On Standard/Enterprise you would schedule THIS SAME procedure with a SQL
   Agent job (one line: EXEC dbo.usp_RunMaintenance). The procedure doesn't
   change — only the scheduler does.
   ============================================================================ */

USE SCV_Operations;
GO

-- Drop and recreate so the script is re-runnable
IF OBJECT_ID('dbo.usp_RunMaintenance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RunMaintenance;
GO

-- A small table to record each maintenance run (so you have an audit trail
-- proving the schedule actually fired — this is your evidence later).
IF OBJECT_ID('dbo.Maintenance_Log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Maintenance_Log (
        run_id        INT           IDENTITY(1,1) PRIMARY KEY,
        run_at        DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
        action_taken  VARCHAR(200)  NOT NULL,
        details       VARCHAR(1000) NULL
    );
END
GO

CREATE PROCEDURE dbo.usp_RunMaintenance
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Record that maintenance started
    INSERT INTO dbo.Maintenance_Log (action_taken, details)
    VALUES ('Maintenance run started', 'Called by scheduler');

    -- 2) Reorganize any fragmented indexes on the busy table.
    --    (Light-touch: REORGANIZE is online and safe to run routinely.)
    DECLARE @frag FLOAT;
    SELECT @frag = MAX(ips.avg_fragmentation_in_percent)
    FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Usage_Readings'), NULL, NULL, 'LIMITED') AS ips
    WHERE ips.index_id > 0;

    IF @frag >= 5
    BEGIN
        ALTER INDEX ALL ON Usage_Readings REORGANIZE;
        INSERT INTO dbo.Maintenance_Log (action_taken, details)
        VALUES ('Reorganized indexes on Usage_Readings',
                'Fragmentation was ' + CAST(ROUND(@frag, 1) AS VARCHAR(20)) + '%');
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Maintenance_Log (action_taken, details)
        VALUES ('Index check: no action needed',
                'Fragmentation ' + ISNULL(CAST(ROUND(@frag,1) AS VARCHAR(20)),'n/a') + '% (below 5% threshold)');
    END

    -- 3) Update statistics so the query optimizer has fresh information
    --    (helps it keep choosing good plans).
    EXEC sp_updatestats;
    INSERT INTO dbo.Maintenance_Log (action_taken, details)
    VALUES ('Updated statistics', 'sp_updatestats completed');

    -- 4) Capacity snapshot: record current row counts so growth is trackable
    DECLARE @readings INT = (SELECT COUNT(*) FROM Usage_Readings);
    DECLARE @alerts   INT = (SELECT COUNT(*) FROM System_Alerts);
    INSERT INTO dbo.Maintenance_Log (action_taken, details)
    VALUES ('Capacity snapshot',
            'Usage_Readings rows=' + CAST(@readings AS VARCHAR(20)) +
            ', open System_Alerts=' + CAST(@alerts AS VARCHAR(20)));

    -- 5) Record completion
    INSERT INTO dbo.Maintenance_Log (action_taken, details)
    VALUES ('Maintenance run completed', 'All steps finished');
END
GO

/* ----------------------------------------------------------------------------
   TEST IT MANUALLY FIRST (before scheduling):
   Run these two lines. You should see rows appear in Maintenance_Log.
   ---------------------------------------------------------------------------- */
EXEC dbo.usp_RunMaintenance;
GO

SELECT * FROM dbo.Maintenance_Log ORDER BY run_at DESC;
GO
