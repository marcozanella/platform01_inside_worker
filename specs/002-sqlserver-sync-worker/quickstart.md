# Quickstart: SQL Server Sync Worker

**Feature**: 002-sqlserver-sync-worker  
**Date**: 2025-12-14  
**Phase**: 1 (Design & Contracts)

---

## Overview

This guide covers setup, testing, and troubleshooting for the SQL Server sync worker that imports OpenOrder data every 5 minutes.

---

## Prerequisites

### System Requirements

- **Ruby**: 3.3.5 (already installed)
- **Rails**: 8.1.1 (already installed)
- **FreeTDS**: Required for TinyTDS to connect to SQL Server
- **Docker**: Application runs in Docker environment

### SQL Server Access

- **Server**: CASQL2.inxintl.com
- **Database**: ProcessStatus
- **View**: vwZSDOrder_Advanced
- **Username**: zsdOrder8800
- **Password**: 3~EmX~Kf$}
- **Network**: Must be on firewalled internal network

---

## Installation

### 1. Install FreeTDS (Docker)

Add to `Dockerfile`:

```dockerfile
# Install FreeTDS for SQL Server connectivity
RUN apt-get update && \
    apt-get install -y freetds-dev freetds-bin && \
    rm -rf /var/lib/apt/lists/*
```

### 2. Install TinyTDS Gem

Add to `Gemfile`:

```ruby
# SQL Server connectivity
gem 'tinytds', '~> 2.1'
```

Run:

```bash
bundle install
```

### 3. Configure SQL Server Connection

Add to `config/database.yml`:

```yaml
# SQL Server connection for SAP data sync
sqlserver:
  adapter: sqlserver
  mode: dblib
  host: CASQL2.inxintl.com
  database: ProcessStatus
  username: zsdOrder8800
  password: <%= ENV.fetch('SQL_SERVER_PASSWORD', '3~EmX~Kf$}') %>
  timeout: 30
  encoding: utf8
```

**Security Note**: Password in file acceptable per clarifications (firewalled network). For production external deployment, use `ENV['SQL_SERVER_PASSWORD']` only.

### 4. Configure Recurring Job

Add to `config/recurring.yml`:

```yaml
sync_open_orders:
  class: SyncOpenOrdersJob
  schedule: "*/5 * * * *"  # Every 5 minutes
  queue: default
```

### 5. Rebuild Docker Container

```bash
docker-compose build
docker-compose up -d
```

---

## Manual Testing

### Test SQL Server Connection

```bash
bin/rails runner "
  config = Rails.configuration.database_configuration['sqlserver']
  client = TinyTds::Client.new(
    host: config['host'],
    username: config['username'],
    password: config['password'],
    database: config['database'],
    timeout: config['timeout']
  )
  puts 'Connection successful!' if client.active?
  client.close
"
```

**Expected**: `Connection successful!`

### Test Query Execution

```bash
bin/rails runner "
  connector = SqlServerConnector.new
  count = connector.execute('SELECT COUNT(*) as cnt FROM vwZSDOrder_Advanced').first['cnt']
  puts \"Found #{count} records in SQL Server\"
"
```

**Expected**: `Found 1500-3000 records in SQL Server` (typical range)

### Run Manual Sync (via Rake task)

```bash
bin/rails sync:open_orders
```

**Expected Output**:

```
[INFO] Starting OpenOrder sync from SQL Server
[INFO] Connected to SQL Server: CASQL2.inxintl.com/ProcessStatus
[INFO] Fetched 2,435 records from vwZSDOrder_Advanced
[INFO] Imported batch of 500 records (total: 500)
[INFO] Imported batch of 500 records (total: 1000)
[INFO] Imported batch of 500 records (total: 1500)
[INFO] Imported batch of 500 records (total: 2000)
[INFO] Imported batch of 435 records (total: 2435)
[INFO] Sync completed successfully: 2,435 records imported
[INFO] Sync duration: 12.3 seconds
```

### Run Job Directly

```bash
bin/rails runner "SyncOpenOrdersJob.perform_now"
```

**Expected**: Same output as rake task

### Verify Data Import

```bash
bin/rails runner "
  count = OpenOrder.count
  latest = OpenOrder.order(created_at: :desc).first
  puts \"Total records: #{count}\"
  puts \"Latest record: #{latest.sales_doc} - #{latest.cust_name}\"
"
```

**Expected**:

```
Total records: 2435
Latest record: 9876543210 - ACME Corporation
```

---

## Monitoring

### Check Sync Status (Rails Console)

```ruby
bin/rails console

# Check last sync time
OpenOrder.maximum(:created_at)
# => 2025-12-14 15:32:11 UTC

# Check record count
OpenOrder.count
# => 2435

# Check recent records
OpenOrder.order(created_at: :desc).limit(5).pluck(:sales_doc, :cust_name)
# => [["9876543210", "ACME Corp"], ...]
```

### Check Job Logs

```bash
# View Solid Queue logs
docker-compose logs -f web | grep SyncOpenOrdersJob

# View Rails logs
tail -f log/development.log
```

**Look For**:

- `[INFO] Sync completed successfully: X records imported`
- `[INFO] Sync duration: X seconds`
- `[ERROR] Sync failed: [error message]` (if errors occur)

### Check Solid Queue Dashboard

If configured, access Solid Queue dashboard at `/jobs` route.

---

## Validation Checklist

After deployment, verify:

- [ ] FreeTDS installed in Docker container
- [ ] TinyTDS gem installed (`bundle list | grep tinytds`)
- [ ] SQL Server connection succeeds (test script above)
- [ ] Query returns records (test script above)
- [ ] Manual sync completes without errors
- [ ] Data appears in `open_orders` table
- [ ] Recurring job scheduled (`config/recurring.yml` loaded)
- [ ] Job runs every 5 minutes (check logs)
- [ ] Timestamps update after each sync
- [ ] Old data deleted and replaced (transaction works)

---

## Troubleshooting

### Connection Errors

#### Error: "Unable to connect to SQL Server"

**Cause**: Network not accessible or credentials wrong

**Solutions**:

1. Verify network access: `ping CASQL2.inxintl.com`
2. Check credentials in `database.yml`
3. Verify SQL Server is running
4. Check firewall rules

#### Error: "Login failed for user 'zsdOrder8800'"

**Cause**: Invalid credentials or account locked

**Solutions**:

1. Verify password: `3~EmX~Kf$}`
2. Contact SQL Server admin to unlock account
3. Test login with SQL Server Management Studio

#### Error: "Cannot open database ProcessStatus"

**Cause**: Database name wrong or no access

**Solutions**:

1. Verify database name: `ProcessStatus`
2. Check user has read access to database
3. Test with: `SELECT DB_NAME()`

---

### Query Errors

#### Error: "Invalid object name 'vwZSDOrder_Advanced'"

**Cause**: View doesn't exist or no access

**Solutions**:

1. Verify view exists: `SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'vwZSDOrder_Advanced'`
2. Check user has SELECT permission on view
3. Verify view in correct schema (might be `dbo.vwZSDOrder_Advanced`)

#### Error: "Column 'XYZ' not found"

**Cause**: Column mapping mismatch with SQL Server schema

**Solutions**:

1. Check SQL Server schema: `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vwZSDOrder_Advanced'`
2. Update `COLUMN_MAPPING` in `open_orders_importer.rb`
3. Verify column name capitalization matches

---

### Import Errors

#### Error: "ActiveRecord::RecordInvalid"

**Cause**: Data validation failed (shouldn't happen - no validations)

**Solutions**:

1. Check OpenOrder model for unexpected validations
2. Check database constraints (should be none except primary key)
3. Review error message for specific field

#### Error: "Transaction rolled back"

**Cause**: Database error during insert

**Solutions**:

1. Check database disk space
2. Check SQLite database not corrupted: `bin/rails db:check`
3. Review logs for specific error
4. Try smaller batch size (reduce from 500)

#### Error: "Batch insert failed"

**Cause**: insert_all failed (malformed data)

**Solutions**:

1. Check for special characters in text fields
2. Check for invalid dates (e.g., '0000-00-00')
3. Add more type conversion guards in `convert_value`
4. Log problematic records before insert

---

### Performance Issues

#### Sync Takes Too Long (>30 seconds)

**Cause**: Network latency or large dataset

**Solutions**:

1. Check network speed to CASQL2.inxintl.com
2. Reduce batch size in `COLUMN_MAPPING` (e.g., 250 instead of 500)
3. Add index to SQL Server view (if possible)
4. Consider pagination if dataset exceeds 10,000 records

#### Memory Usage High

**Cause**: Loading too many records at once

**Solutions**:

1. Reduce batch size: `BATCH_SIZE = 250`
2. Process query results in cursor mode (stream results)
3. Monitor Docker container memory: `docker stats`

---

### Job Scheduling Issues

#### Job Not Running Automatically

**Cause**: Recurring job not registered or Solid Queue not running

**Solutions**:

1. Verify `config/recurring.yml` loaded: `bin/rails runner "puts Solid::RecurringTask.all.inspect"`
2. Check Solid Queue process running: `ps aux | grep solid`
3. Restart application: `docker-compose restart web`
4. Check logs for job scheduler errors

#### Job Running Concurrently

**Cause**: Previous job still running when next job starts (shouldn't happen - Solid Queue prevents this)

**Solutions**:

1. Verify job duration < 5 minutes (check logs)
2. Increase sync interval to `*/10 * * * *` (every 10 minutes)
3. Check for stuck jobs: `Solid::Job.where(status: 'executing')`

---

## Emergency Procedures

### Stop Syncing

**To temporarily disable**:

1. Comment out job in `config/recurring.yml`:

```yaml
# sync_open_orders:
#   class: SyncOpenOrdersJob
#   schedule: "*/5 * * * *"
```

2. Restart application:

```bash
docker-compose restart web
```

### Restore Old Data

**If sync corrupts data**:

1. Restore from database backup (if configured)
2. Re-run sync manually after fixing issue:

```bash
bin/rails sync:open_orders
```

### Force Manual Sync

**To sync immediately**:

```bash
bin/rails sync:open_orders
```

Or via console:

```ruby
SyncOpenOrdersJob.perform_now
```

---

## Development Tips

### Test with Smaller Dataset

Modify query in `sql_server_connector.rb`:

```ruby
SELECT TOP 100 * FROM vwZSDOrder_Advanced  # Test with 100 records
```

### Dry Run (No Database Changes)

Add dry run mode to importer:

```ruby
def self.import(sql_rows, dry_run: false)
  return 0 if sql_rows.empty?
  
  if dry_run
    puts "DRY RUN: Would import #{sql_rows.size} records"
    return sql_rows.size
  end
  
  # ... actual import logic
end
```

### Debug Column Mapping

Log unmapped columns:

```ruby
sql_row.keys.each do |sql_column|
  unless COLUMN_MAPPING.key?(sql_column)
    Rails.logger.warn "Unmapped SQL Server column: #{sql_column}"
  end
end
```

---

## Next Steps

1. **Implement services**: Create `SqlServerConnector` and `OpenOrdersImporter`
2. **Implement job**: Create `SyncOpenOrdersJob`
3. **Create rake task**: Create `lib/tasks/sync.rake`
4. **Test connection**: Run connection test script
5. **Test query**: Run query test script
6. **Run manual sync**: Execute `bin/rails sync:open_orders`
7. **Verify data**: Check `open_orders` table has records
8. **Enable recurring**: Restart app to load `recurring.yml`
9. **Monitor logs**: Watch for 5-minute executions
10. **User Story 4**: Add status page showing last sync time

---

## Support

For issues not covered here:

1. Check Rails logs: `log/development.log`
2. Check Docker logs: `docker-compose logs web`
3. Check SQL Server logs (contact DBA)
4. Review data-model.md for column mapping details
5. Review research.md for technical decisions

---

**Status**: Phase 1 quickstart complete ✅ - Ready for implementation and testing.
