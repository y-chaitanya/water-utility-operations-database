/* ============================================================================
   06_capacity_monitoring.sql
   SCV Water Operations Database - Capacity & Performance Monitoring
   ----------------------------------------------------------------------------
   Purpose : Routine health checks a DBA runs to support proactive capacity
             planning and to catch performance problems early. Maps to the
             "monitors transaction logs and growth" and "responds to performance
             issues" duties.
   Layout  : Section A) Capacity & space     Section B) Performance health
   Run     : Execute against SCV_Operations.
   ============================================================================ */

USE SCV_Operations;
GO
SET NOCOUNT ON;

/* ============================================================================
   SECTION A - CAPACITY & SPACE
   ============================================================================ */

/* A1) Data (.mdf) and log (.ldf) file size, used space, free space, autogrowth.
       Track free space trending down over time to grow files before you run out. */
PRINT 'A1) Database file allocation and free space';
SELECT
    f.name                                                              AS logical_file,
    f.type_desc                                                         AS file_type,
    CAST(f.size * 8.0 / 1024 AS DECIMAL(12,2))                          AS allocated_mb,
    CAST(FILEPROPERTY(f.name,'SpaceUsed') * 8.0 / 1024 AS DECIMAL(12,2)) AS used_mb,
    CAST((f.size - FILEPROPERTY(f.name,'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(12,2)) AS free_mb,
    CASE f.is_percent_growth
         WHEN 1 THEN CAST(f.growth AS VARCHAR(10)) + ' %'
         ELSE CAST(f.growth * 8 / 1024 AS VARCHAR(10)) + ' MB'
    END                                                                 AS autogrowth
FROM sys.database_files f;
GO

/* A2) Transaction-log space usage (don't let the logbook fill up and stall). */
PRINT 'A2) Transaction-log space';
DBCC SQLPERF(LOGSPACE);
GO

/* A3) Per-table size and row counts - where is the data actually growing? */
PRINT 'A3) Space and rows by table';
SELECT
    t.name                                                  AS table_name,
    SUM(p.rows)                                             AS row_count,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(12,2))  AS total_mb,
    CAST(SUM(a.used_pages)  * 8.0 / 1024 AS DECIMAL(12,2))  AS used_mb
FROM sys.tables t
JOIN sys.indexes i        ON i.object_id = t.object_id
JOIN sys.partitions p     ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN sys.allocation_units a ON a.container_id = p.partition_id
WHERE i.index_id IN (0,1)        -- heap or clustered index = the base table
GROUP BY t.name
ORDER BY total_mb DESC;
GO

/* ============================================================================
   SECTION B - PERFORMANCE HEALTH
   ============================================================================ */

/* B1) Ensure a helpful index exists where queries filter/join often.
       "Show a meter's readings over time" filters by meter_id and orders by
       read_at; the index lets SQL Server jump straight to those rows. */
PRINT 'B1) Ensure supporting index exists';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Usage_Meter_Time')
    CREATE INDEX IX_Usage_Meter_Time ON Usage_Readings (meter_id, read_at);
GO

-- See the effect: compare "logical reads" reported in the Messages tab.
SET STATISTICS IO ON;
SELECT meter_id, read_at, reading_value
FROM Usage_Readings
WHERE meter_id = 1
ORDER BY read_at;
SET STATISTICS IO OFF;
GO

/* B2) Most time-consuming queries on the server (find the "clogged pipes"). */
PRINT 'B2) Top queries by total elapsed time';
SELECT TOP 5
    qs.execution_count,
    qs.total_elapsed_time / 1000 AS total_ms,
    SUBSTRING(t.text, 1, 150)    AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
ORDER BY qs.total_elapsed_time DESC;
GO

/* B3) Index usage - are our indexes earning their keep, or just costing writes? */
PRINT 'B3) Index usage stats for this database';
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name                   AS index_name,
    us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id
      AND us.database_id = DB_ID()
WHERE i.object_id > 100 AND i.name IS NOT NULL
ORDER BY table_name, index_name;
GO

PRINT 'Capacity and performance monitoring complete.';
GO
