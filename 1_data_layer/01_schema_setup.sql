/* ============================================================================
   01_schema_setup.sql
   SCV Water Operations Database - Schema, Keys & Constraints
   ----------------------------------------------------------------------------
   Purpose : Create the database and core tables with full referential
             integrity (primary keys, foreign keys) and data-validation
             constraints (NOT NULL, CHECK, UNIQUE, DEFAULT).
   Engine  : Microsoft SQL Server (T-SQL). Tested target: SQL Server 2022.
   Note    : All data is synthetic and generated for practice only.
   Run     : Execute this file FIRST. It is re-runnable (drops & recreates
             the tables each time).
   ============================================================================ */

-- Create the database only if it does not already exist
IF DB_ID('SCV_Operations') IS NULL
    CREATE DATABASE SCV_Operations;
GO

USE SCV_Operations;
GO

/* ----------------------------------------------------------------------------
   Drop existing tables in reverse dependency order so the script is re-runnable.
   Child tables (with foreign keys) must be dropped before their parents.
   ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS System_Alerts;
DROP TABLE IF EXISTS Audit_Log;
DROP TABLE IF EXISTS Billing;
DROP TABLE IF EXISTS Usage_Readings;
DROP TABLE IF EXISTS Meters;
DROP TABLE IF EXISTS Customers;
GO

/* ----------------------------------------------------------------------------
   Customers - the people we serve and bill.
   PRIMARY KEY : customer_id     (unique identity for each customer)
   UNIQUE      : account_number  (no two customers share an account number)
   ---------------------------------------------------------------------------- */
CREATE TABLE Customers (
    customer_id      INT            IDENTITY(1,1) NOT NULL,
    account_number   VARCHAR(20)    NOT NULL,
    first_name       VARCHAR(50)    NOT NULL,
    last_name        VARCHAR(50)    NOT NULL,
    service_address  VARCHAR(200)   NOT NULL,
    email            VARCHAR(100)   NULL,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Customers       PRIMARY KEY (customer_id),
    CONSTRAINT UQ_Customers_Acct  UNIQUE (account_number)
);
GO

/* ----------------------------------------------------------------------------
   Meters - the physical water meters, each owned by one customer.
   FOREIGN KEY : customer_id -> Customers (the "pipe joint" linking the tables)
   CHECK       : meter_size_inches > 0, and status limited to a known set
   ---------------------------------------------------------------------------- */
CREATE TABLE Meters (
    meter_id          INT           IDENTITY(1,1) NOT NULL,
    meter_number      VARCHAR(20)   NOT NULL,
    customer_id       INT           NOT NULL,
    meter_size_inches DECIMAL(4,2)  NOT NULL,
    status            VARCHAR(20)   NOT NULL DEFAULT 'Active',
    installed_on      DATE          NOT NULL,
    CONSTRAINT PK_Meters            PRIMARY KEY (meter_id),
    CONSTRAINT UQ_Meters_Number     UNIQUE (meter_number),
    CONSTRAINT FK_Meters_Customers  FOREIGN KEY (customer_id)
        REFERENCES Customers (customer_id),
    CONSTRAINT CK_Meters_Size       CHECK (meter_size_inches > 0),
    CONSTRAINT CK_Meters_Status     CHECK (status IN ('Active','Inactive','Removed','Faulty'))
);
GO

/* ----------------------------------------------------------------------------
   Usage_Readings - consumption recorded per meter per read.
   reading_value is consumption (gallons) for the period, so it can never be
   negative -> enforced by CHECK. A duplicate read for the same meter at the
   same timestamp is prevented by a composite UNIQUE constraint.
   ---------------------------------------------------------------------------- */
CREATE TABLE Usage_Readings (
    reading_id     INT            IDENTITY(1,1) NOT NULL,
    meter_id       INT            NOT NULL,
    reading_value  DECIMAL(12,2)  NOT NULL,
    read_at        DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Usage_Readings    PRIMARY KEY (reading_id),
    CONSTRAINT FK_Usage_Meters      FOREIGN KEY (meter_id)
        REFERENCES Meters (meter_id),
    CONSTRAINT CK_Usage_NonNegative CHECK (reading_value >= 0),
    CONSTRAINT UQ_Usage_Meter_Time  UNIQUE (meter_id, read_at)
);
GO

/* ----------------------------------------------------------------------------
   Billing - charges per customer per billing period.
   Table-level CHECK ensures the period end is on or after the period start.
   ---------------------------------------------------------------------------- */
CREATE TABLE Billing (
    bill_id               INT            IDENTITY(1,1) NOT NULL,
    customer_id           INT            NOT NULL,
    billing_period_start  DATE           NOT NULL,
    billing_period_end    DATE           NOT NULL,
    amount_due            DECIMAL(10,2)  NOT NULL,
    paid                  BIT            NOT NULL DEFAULT 0,
    CONSTRAINT PK_Billing            PRIMARY KEY (bill_id),
    CONSTRAINT FK_Billing_Customers  FOREIGN KEY (customer_id)
        REFERENCES Customers (customer_id),
    CONSTRAINT CK_Billing_Amount     CHECK (amount_due >= 0),
    CONSTRAINT CK_Billing_Period     CHECK (billing_period_end >= billing_period_start)
);
GO

/* ----------------------------------------------------------------------------
   Audit_Log - written automatically by a trigger (see 03_audit_and_alert_triggers.sql).
   Audit tables deliberately avoid a foreign key to the table they track, so an
   audit write can never be blocked by a lock or a delete on the source row.
   ---------------------------------------------------------------------------- */
CREATE TABLE Audit_Log (
    audit_id     INT            IDENTITY(1,1) NOT NULL,
    meter_id     INT            NOT NULL,
    old_status   VARCHAR(20)    NULL,
    new_status   VARCHAR(20)    NOT NULL,
    changed_by   SYSNAME        NOT NULL,
    changed_at   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Audit_Log PRIMARY KEY (audit_id)
);
GO

/* ----------------------------------------------------------------------------
   System_Alerts - written automatically by a trigger when a reading looks like
   a possible leak or meter fault (see 03_audit_and_alert_triggers.sql).
   ---------------------------------------------------------------------------- */
CREATE TABLE System_Alerts (
    alert_id       INT            IDENTITY(1,1) NOT NULL,
    meter_id       INT            NOT NULL,
    reading_value  DECIMAL(12,2)  NOT NULL,
    alert_type     VARCHAR(50)    NOT NULL,
    raised_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    reviewed       BIT            NOT NULL DEFAULT 0,
    CONSTRAINT PK_System_Alerts PRIMARY KEY (alert_id)
);
GO

/* ============================================================================
   SAMPLE DATA (synthetic)
   Parent rows are inserted first, then child rows look up their parent by the
   parent's UNIQUE business key (account_number / meter_number). This keeps the
   seed data correct without relying on guessed identity values.
   ============================================================================ */

INSERT INTO Customers (account_number, first_name, last_name, service_address, email) VALUES
    ('ACC-1001', 'Maria', 'Gonzalez', '123 Aqua Lane, Santa Clarita, CA',      'maria.g@example.com'),
    ('ACC-1002', 'James', 'Tanaka',   '456 Reservoir Road, Santa Clarita, CA', 'james.t@example.com'),
    ('ACC-1003', 'Priya', 'Patel',    '789 Canyon Drive, Santa Clarita, CA',   NULL),
    ('ACC-1004', 'David', 'Nguyen',   '321 Mesa Way, Santa Clarita, CA',       'david.n@example.com');
GO

INSERT INTO Meters (meter_number, customer_id, meter_size_inches, status, installed_on)
SELECT 'MTR-001', customer_id, 0.75, 'Active', '2022-03-15' FROM Customers WHERE account_number = 'ACC-1001'
UNION ALL
SELECT 'MTR-002', customer_id, 1.00, 'Active', '2021-07-01' FROM Customers WHERE account_number = 'ACC-1002'
UNION ALL
SELECT 'MTR-003', customer_id, 0.75, 'Active', '2023-01-10' FROM Customers WHERE account_number = 'ACC-1003'
UNION ALL
SELECT 'MTR-004', customer_id, 2.00, 'Active', '2020-05-20' FROM Customers WHERE account_number = 'ACC-1004';
GO

INSERT INTO Usage_Readings (meter_id, reading_value, read_at)
SELECT meter_id, 1200.00, '2025-04-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-001'
UNION ALL SELECT meter_id, 1450.00, '2025-05-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-001'
UNION ALL SELECT meter_id, 1320.00, '2025-06-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-001'
UNION ALL SELECT meter_id, 5400.00, '2025-05-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-002'
UNION ALL SELECT meter_id, 5600.00, '2025-06-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-002'
UNION ALL SELECT meter_id,  800.00, '2025-05-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-003'
UNION ALL SELECT meter_id,  950.00, '2025-06-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-003'
UNION ALL SELECT meter_id,18000.00, '2025-05-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-004'
UNION ALL SELECT meter_id,17500.00, '2025-06-01T08:00:00' FROM Meters WHERE meter_number = 'MTR-004';
GO

INSERT INTO Billing (customer_id, billing_period_start, billing_period_end, amount_due, paid)
SELECT customer_id, '2025-05-01', '2025-05-31',  84.50, 1 FROM Customers WHERE account_number = 'ACC-1001'
UNION ALL
SELECT customer_id, '2025-05-01', '2025-05-31', 156.00, 0 FROM Customers WHERE account_number = 'ACC-1002'
UNION ALL
SELECT customer_id, '2025-05-01', '2025-05-31', 540.25, 0 FROM Customers WHERE account_number = 'ACC-1004';
GO

PRINT 'Schema created and sample data loaded successfully.';
GO
