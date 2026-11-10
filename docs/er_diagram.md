# Entity Relationship Diagram

SCV Water Operations Database (`SCV_Operations`, Microsoft SQL Server). Generated from `01_schema_setup.sql`. All data is synthetic.

```mermaid
erDiagram
    Customers ||--o{ Meters : "owns"
    Customers ||--o{ Billing : "is billed"
    Meters ||--o{ Usage_Readings : "records"
    Meters ||..o{ Audit_Log : "status changes (no FK)"
    Meters ||..o{ System_Alerts : "raises (no FK)"

    Customers {
        INT customer_id PK
        VARCHAR account_number UK
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR service_address
        VARCHAR email "nullable"
        DATETIME2 created_at
    }
    Meters {
        INT meter_id PK
        VARCHAR meter_number UK
        INT customer_id FK
        DECIMAL meter_size_inches "CHECK > 0"
        VARCHAR status "Active, Inactive, Removed, Faulty"
        DATE installed_on
    }
    Usage_Readings {
        INT reading_id PK
        INT meter_id FK
        DECIMAL reading_value "gallons, CHECK >= 0"
        DATETIME2 read_at "UNIQUE with meter_id"
    }
    Billing {
        INT bill_id PK
        INT customer_id FK
        DATE billing_period_start
        DATE billing_period_end "CHECK >= start"
        DECIMAL amount_due "CHECK >= 0"
        BIT paid
    }
    Audit_Log {
        INT audit_id PK
        INT meter_id "logical link, no FK"
        VARCHAR old_status "nullable"
        VARCHAR new_status
        SYSNAME changed_by
        DATETIME2 changed_at
    }
    System_Alerts {
        INT alert_id PK
        INT meter_id "logical link, no FK"
        DECIMAL reading_value
        VARCHAR alert_type
        DATETIME2 raised_at
        BIT reviewed
    }
```

Solid lines are enforced foreign keys. Dotted lines are logical links with no foreign key: `Audit_Log` and `System_Alerts` are written by triggers and deliberately avoid a foreign key so a log write is never blocked by a lock or delete on the source row.
