/* ============================================================================
   07_index_tuning_demo.sql
   PURPOSE: Demonstrate query performance tuning with an index — the
            "before and after" a DBA looks for when a query is slow.

   Maps to SCV Water duty: "monitors growth ... responds to performance issues"
   and "develops and configures database management tools."

   RUNS IN: SQL Server Express (Docker) — indexing is fully supported in Express.
            Nothing here needs Enterprise/Standard.

   HOW TO READ THE RESULT:
   - Turn on "Include Actual Execution Plan" in VS Code / SSMS (or use the
     SET STATISTICS lines below) BEFORE running the SELECTs.
   - BEFORE the index: the plan shows a "Table Scan" / "Clustered Index Scan"
     — SQL Server reads the whole table to find matching rows (slow at scale).
   - AFTER the index: the plan shows an "Index Seek" — SQL Server jumps
     straight to the matching rows (fast).
   ============================================================================ */

USE SCV_Operations;
GO

/* ----------------------------------------------------------------------------
   STEP 0 (optional): make the demo visible at small data sizes.
   With only a handful of rows, SQL Server may scan regardless because a scan
   is cheap. To SEE the difference clearly, we add more synthetic readings.
   This is still synthetic sandbox data — just more of it.
   ---------------------------------------------------------------------------- */

-- Add ~50,000 synthetic readings spread across existing meters so the
-- performance difference is measurable. Safe to re-run-safe? No — run once.
SET NOCOUNT ON;

DECLARE @i INT = 1;
DECLARE @maxMeter INT = (SELECT MAX(meter_id) FROM Meters);

-- Guard: only seed if we have meters and the table is still small
IF @maxMeter IS NOT NULL AND (SELECT COUNT(*) FROM Usage_Readings) < 1000
BEGIN
    WHILE @i <= 50000
    BEGIN
        INSERT INTO Usage_Readings (meter_id, reading_value, read_at)
        VALUES (
            ((@i % @maxMeter) + 1),                       -- cycle through meters
            ROUND(RAND() * 1000, 2),                      -- random normal reading
            DATEADD(MINUTE, -@i, SYSUTCDATETIME())        -- spread across time
        );
        SET @i += 1;
    END
END
GO

/* ----------------------------------------------------------------------------
   STEP 1 — BEFORE: run a typical lookup and capture the cost.
   This is the kind of query the app runs constantly:
   "give me the recent readings for one meter."
   ---------------------------------------------------------------------------- */

SET STATISTICS IO ON;      -- shows how many pages SQL Server had to read
SET STATISTICS TIME ON;    -- shows how long it took
GO

PRINT '--- BEFORE INDEX: lookup readings for meter_id = 3 ---';
SELECT reading_id, meter_id, reading_value, read_at
FROM Usage_Readings
WHERE meter_id = 3
ORDER BY read_at DESC;
GO
-- ^ Look at the execution plan: expect a SCAN (reads the whole table).
--   In the Messages tab, note the "logical reads" number — it's high.

/* ----------------------------------------------------------------------------
   STEP 2 — ADD THE INDEX (the directory map).
   A non-clustered index on (meter_id, read_at) lets SQL Server jump straight
   to one meter's rows, already ordered by time — which also serves the
   ORDER BY for free.
   ---------------------------------------------------------------------------- */

PRINT '--- Creating index idx_readings_meter_time ---';
CREATE NONCLUSTERED INDEX idx_readings_meter_time
    ON Usage_Readings (meter_id, read_at DESC)
    INCLUDE (reading_value);     -- "covering" the query so it needs nothing else
GO

/* ----------------------------------------------------------------------------
   STEP 3 — AFTER: run the exact same query again.
   ---------------------------------------------------------------------------- */

PRINT '--- AFTER INDEX: same lookup for meter_id = 3 ---';
SELECT reading_id, meter_id, reading_value, read_at
FROM Usage_Readings
WHERE meter_id = 3
ORDER BY read_at DESC;
GO
-- ^ Now the plan shows an INDEX SEEK, and "logical reads" drops sharply.
--   Same answer, far less work. That is the tuning win.

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ----------------------------------------------------------------------------
   STEP 4 — HOW A DBA FINDS WHAT TO TUNE (the missing-index hints).
   SQL Server tracks indexes it WISHES existed. This is where you'd look to
   decide what to build next — not guesswork.
   ---------------------------------------------------------------------------- */

PRINT '--- Missing-index suggestions SQL Server has recorded ---';
SELECT
    mid.statement              AS table_name,
    migs.avg_user_impact       AS estimated_pct_improvement,
    migs.user_seeks + migs.user_scans AS times_it_would_have_helped,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_group_stats AS migs
JOIN sys.dm_db_missing_index_groups       AS mig  ON migs.group_handle = mig.index_group_handle
JOIN sys.dm_db_missing_index_details      AS mid  ON mig.index_handle  = mid.index_handle
ORDER BY migs.avg_user_impact DESC;
GO

/* ----------------------------------------------------------------------------
   STEP 5 — CHECK FOR INDEX FRAGMENTATION (maintenance awareness).
   Over time indexes fragment and need REORGANIZE (light) or REBUILD (heavy).
   Rule of thumb: <5% leave it, 5–30% reorganize, >30% rebuild.
   ---------------------------------------------------------------------------- */

PRINT '--- Index fragmentation on Usage_Readings ---';
SELECT
    i.name                              AS index_name,
    ips.avg_fragmentation_in_percent    AS fragmentation_pct,
    ips.page_count,
    CASE
        WHEN ips.avg_fragmentation_in_percent < 5  THEN 'OK - leave it'
        WHEN ips.avg_fragmentation_in_percent <= 30 THEN 'REORGANIZE'
        ELSE 'REBUILD'
    END AS recommended_action
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Usage_Readings'), NULL, NULL, 'LIMITED') AS ips
JOIN sys.indexes AS i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

/* Example maintenance commands (run when fragmentation warrants):
   ALTER INDEX idx_readings_meter_time ON Usage_Readings REORGANIZE;
   ALTER INDEX idx_readings_meter_time ON Usage_Readings REBUILD;
*/

PRINT '--- Index tuning demo complete ---';
GO
