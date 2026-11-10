# Data Dictionary

SCV Water Operations Database (`SCV_Operations`, Microsoft SQL Server 2022). Source: `01_schema_setup.sql`. All data is synthetic.

Key: PK = primary key, FK = foreign key, UK = unique key.

## Customers
The people the utility serves and bills.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| customer_id | INT IDENTITY | No | PK | System-generated identifier for a customer. |
| account_number | VARCHAR(20) | No | UK | Business account number (format `ACC-####`); no two customers share one. |
| first_name | VARCHAR(50) | No | | Customer first name. |
| last_name | VARCHAR(50) | No | | Customer last name. |
| service_address | VARCHAR(200) | No | | Address where water service is delivered. |
| email | VARCHAR(100) | Yes | | Contact email; optional. |
| created_at | DATETIME2 | No | Default UTC now | When the customer record was created (UTC). |

## Meters
Physical water meters. Each meter belongs to one customer; a customer can have many meters.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| meter_id | INT IDENTITY | No | PK | System-generated identifier for a meter. |
| meter_number | VARCHAR(20) | No | UK | Business meter number (format `MTR-###`). |
| customer_id | INT | No | FK to Customers | Customer who owns the meter. |
| meter_size_inches | DECIMAL(4,2) | No | CHECK > 0 | Meter size in inches. |
| status | VARCHAR(20) | No | CHECK in list; default `Active` | One of Active, Inactive, Removed, Faulty. |
| installed_on | DATE | No | | Date the meter was installed. |

## Usage_Readings
Consumption recorded for a meter at a point in time.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| reading_id | INT IDENTITY | No | PK | System-generated identifier for a reading. |
| meter_id | INT | No | FK to Meters | Meter the reading belongs to. |
| reading_value | DECIMAL(12,2) | No | CHECK >= 0 | Consumption in gallons for the period (not a cumulative dial reading). |
| read_at | DATETIME2 | No | Default UTC now; UK with meter_id | When the reading was taken; one reading per meter per timestamp. |

## Billing
Charges for a customer for a billing period.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| bill_id | INT IDENTITY | No | PK | System-generated identifier for a bill. |
| customer_id | INT | No | FK to Customers | Customer being billed. |
| billing_period_start | DATE | No | | First day of the billing period. |
| billing_period_end | DATE | No | CHECK >= start | Last day of the billing period. |
| amount_due | DECIMAL(10,2) | No | CHECK >= 0 | Amount owed in US dollars. |
| paid | BIT | No | Default 0 | 1 if paid, 0 if unpaid. |

## Audit_Log
Written automatically by a trigger when a meter's status changes.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| audit_id | INT IDENTITY | No | PK | System-generated identifier for an audit entry. |
| meter_id | INT | No | Logical link to Meters (no FK, by design) | Meter whose status changed. |
| old_status | VARCHAR(20) | Yes | | Status before the change. |
| new_status | VARCHAR(20) | No | | Status after the change. |
| changed_by | SYSNAME | No | | Database login that made the change. |
| changed_at | DATETIME2 | No | Default UTC now | When the change happened (UTC). |

## System_Alerts
Written automatically by a trigger when a reading looks like a possible leak or meter fault.

| Column | Data type | Null | Key / constraint | Definition |
|---|---|---|---|---|
| alert_id | INT IDENTITY | No | PK | System-generated identifier for an alert. |
| meter_id | INT | No | Logical link to Meters (no FK) | Meter that raised the alert. |
| reading_value | DECIMAL(12,2) | No | | Reading that triggered the alert. |
| alert_type | VARCHAR(50) | No | | Kind of alert (for example, possible leak). |
| raised_at | DATETIME2 | No | Default UTC now | When the alert was raised (UTC). |
| reviewed | BIT | No | Default 0 | 1 once a person has reviewed the alert. |
