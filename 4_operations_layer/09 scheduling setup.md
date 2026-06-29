# Scheduling Maintenance in SQL Server Express (Docker) — Without SQL Agent

## The honest problem this solves
SQL Server **Express edition has no SQL Server Agent** — the job scheduler that Standard/Enterprise editions use to run recurring tasks. So I can't schedule a job the "normal" way in this sandbox.

This documents the **working alternative**: wrap the maintenance work in a stored procedure (`08_maintenance_procedure.sql` → `dbo.usp_RunMaintenance`), then use **cron inside the Linux container** to call it on a schedule with `sqlcmd`. Same outcome as a SQL Agent job — an automated, recurring maintenance task — using tools that actually exist in Express.

> **On Standard/Enterprise**, you'd schedule the *same* procedure with a one-line SQL Agent job (`EXEC dbo.usp_RunMaintenance`). The procedure doesn't change; only the scheduler does. Knowing both is the point.

---

## How it fits together
```
cron (inside container)  ──every 5 min──►  sqlcmd  ──►  EXEC dbo.usp_RunMaintenance
                                                              │
                                                              ▼
                                                    writes a row to Maintenance_Log
                                                    (your proof it actually ran)
```

---

## Step-by-step setup

### Prerequisite — run the SQL scripts first
In VS Code (mssql extension), run in order so the procedure and log table exist:
1. `08_maintenance_procedure.sql` — creates `usp_RunMaintenance` and `Maintenance_Log`, and test-runs it once.
   Confirm you see rows in `Maintenance_Log` before continuing.

### Step 1 — Find your container name
On your Mac terminal:
```bash
docker ps
```
Look in the `NAMES` column. Assume it's `sqlserver` below — replace with your actual name.

### Step 2 — Open a shell inside the container (as root, to install cron)
```bash
docker exec -it --user root sqlserver bash
```
You're now *inside* the Linux container.

### Step 3 — Install cron and the SQL command-line tool inside the container
The base SQL Server image is minimal, so install what's missing:
```bash
apt-get update
apt-get install -y cron
```
`sqlcmd` is usually already at `/opt/mssql-tools/bin/sqlcmd` (or `/opt/mssql-tools18/bin/sqlcmd` on newer images). Check which exists:
```bash
ls /opt/mssql-tools*/bin/sqlcmd
```
Note the path it prints — you'll use it in the next step.

### Step 4 — Create the script cron will run
Still inside the container, create a small shell script. Replace `YourStrong!Passw0rd` with your actual SA password, and use the `sqlcmd` path from Step 3:
```bash
cat > /var/opt/mssql/run_maintenance.sh << 'EOF'
#!/bin/bash
# Calls the maintenance procedure and logs output to a file for proof.
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -C \
    -d SCV_Operations \
    -Q "EXEC dbo.usp_RunMaintenance" \
    >> /var/opt/mssql/maintenance_cron.log 2>&1
echo "Ran at $(date)" >> /var/opt/mssql/maintenance_cron.log
EOF

chmod +x /var/opt/mssql/run_maintenance.sh
```
> Note: `-C` trusts the server certificate (needed on the newer `mssql-tools18`). On older `mssql-tools` you can drop `-C`.

### Step 5 — Schedule it with cron
Add a cron entry that runs the script every 5 minutes (for a demo you want it frequent so you can see it work; in production you'd use nightly, e.g. `0 2 * * *`):
```bash
echo "*/5 * * * * root /var/opt/mssql/run_maintenance.sh" >> /etc/crontab
```
Start the cron service:
```bash
service cron start
```

### Step 6 — Watch it actually run (your proof)
Wait 5–10 minutes, then check the log file the script writes:
```bash
cat /var/opt/mssql/maintenance_cron.log
```
And — the real evidence — check the database log from VS Code:
```sql
SELECT * FROM dbo.Maintenance_Log ORDER BY run_at DESC;
```
You'll see **new rows appearing every 5 minutes on their own**, with no one running them manually. That's the automated schedule working. **Screenshot this** — the `Maintenance_Log` rows with their timestamps a few minutes apart is your proof, exactly like the other layers.
