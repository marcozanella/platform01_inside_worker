# Research: SQL Server Sync Worker

**Feature**: 002-sqlserver-sync-worker  
**Date**: 2025-12-14  
**Phase**: 0 (Research & Unknowns Resolution)

## Overview

This document consolidates research findings for implementing a recurring background job that syncs OpenOrder data from SAP SQL Server to the local SQLite database every 5 minutes.

---

## 1. TinyTDS Connection Setup

### Decision: Use TinyTDS with FreeTDS

**Rationale**: TinyTDS is the standard, production-ready SQL Server adapter for Ruby. It uses FreeTDS under the hood and is well-maintained with strong Rails integration support.

**Configuration**:

```yaml
# config/database.yml
sqlserver:
  adapter: sqlserver
  host: CASQL2.inxintl.com
  username: zsdOrder8800
  password: "3~EmX~Kf$}"
  database: ProcessStatus  # Database name (view is vwZSDOrder_Advanced)
  timeout: 30  # Connection timeout in seconds
  encoding: utf8
```

**Connection Strategy**:
- Use ActiveRecord's establish_connection with explicit adapter configuration
- Set 30-second connection timeout (configurable)
- Connection pooling not needed (single background job, not high concurrency)
- Handle TinyTDS::Error exceptions for connection failures

**Alternatives Considered**:
- **ODBC Driver**: More complex setup, requires system-level ODBC configuration
- **activerecord-sqlserver-adapter gem**: Provides additional ActiveRecord features but adds complexity. TinyTDS alone is sufficient for read-only view queries.

**Installation**:
```ruby
# Gemfile
gem 'tinytds', '~> 2.1'
```

FreeTDS is typically installed via system package manager (apt-get, yum) in Docker container.

---

## 2. Column Mapping Strategy

### Decision: Explicit Hash-Based Column Mapping

**Rationale**: Manual hash mapping provides the most control, makes column name differences visible in code, and fails fast when mappings are incomplete. This prevents silent data loss and makes troubleshooting easier.

**Implementation Approach**:

```ruby
# app/services/open_orders_importer.rb
COLUMN_MAPPING = {
  # SQL Server Column => Rails Attribute
  'SalesDoc' => :sales_doc,
  'ItemNumber' => :item_number,
  'CustName' => :cust_name,
  'SoldTo' => :sold_to,
  # ... all 70+ fields mapped explicitly
}.freeze

def map_row(sql_row)
  COLUMN_MAPPING.transform_values { |attr| sql_row[attr.to_s] }
end
```

**Handling Mismatches**:
- **Missing SQL Server columns**: Log warning, use nil value for Rails attribute
- **Extra SQL Server columns**: Ignore (not mapped), log info message
- **Type mismatches**: Handle during transformation (DateTime parsing, Integer conversion)

**Alternatives Considered**:
- **Case-insensitive fuzzy matching**: Too risky, could silently map wrong columns
- **Convention-based (snake_case conversion)**: Doesn't handle abbreviations or different naming schemes
- **Exact name match only**: Too brittle, would require changing model or view column names

---

## 3. Batch Processing with ActiveRecord

### Decision: ActiveRecord.insert_all with 500-record batches

**Rationale**: `ActiveRecord.insert_all` is optimized for bulk inserts in Rails 6+, supports validation skipping (we validate SQL Server data is already clean), and generates efficient SQL. 500-record batches balance memory usage with database performance.

**Implementation Pattern**:

```ruby
def import_records(sql_rows)
  sql_rows.each_slice(500) do |batch|
    mapped_records = batch.map { |row| map_row(row) }
    OpenOrder.insert_all(mapped_records, returning: false)
    Rails.logger.info "Imported batch of #{batch.size} records"
  end
end
```

**Transaction Strategy**:
```ruby
OpenOrder.transaction do
  # 1. Fetch all records from SQL Server first (outside transaction)
  sql_rows = fetch_from_sql_server
  
  # 2. Only if fetch succeeds, truncate and insert within transaction
  OpenOrder.delete_all  # Faster than truncate, works with transactions
  import_records(sql_rows)
end
```

**Memory Management**:
- Expected <5,000 records → ~5-10MB memory footprint (acceptable)
- Batch size of 500 → ~0.5-1MB per batch
- TinyTDS result set can stream rows (doesn't load all into memory at once)

**Alternatives Considered**:
- **Single record inserts**: Too slow, ~5,000 individual INSERTs would take minutes
- **Load all into memory then insert**: Risk with larger datasets, batch approach is safer
- **activerecord-import gem**: Adds dependency, insert_all is built-in and sufficient
- **Smaller batches (100)**: More database round-trips, negligible memory benefit
- **Larger batches (1000)**: Marginal performance gain, higher memory risk

---

## 4. Solid Queue Recurring Job Configuration

### Decision: Use config/recurring.yml with 5-minute interval

**Rationale**: Solid Queue's recurring jobs feature is designed for this exact use case. It handles scheduling, prevents concurrent executions, and integrates with Rails logger.

**Configuration**:

```yaml
# config/recurring.yml
production:
  sync_open_orders:
    class: SyncOpenOrdersJob
    schedule: "*/5 * * * *"  # Every 5 minutes (cron syntax)
    queue: default

development:
  sync_open_orders:
    class: SyncOpenOrdersJob
    schedule: "*/5 * * * *"  # Same schedule for testing
    queue: default
```

**Concurrency Prevention**:
- Solid Queue automatically prevents concurrent executions of the same recurring job
- If job is still running when next schedule hits, it skips the execution
- No additional locking code needed

**Job Implementation**:

```ruby
# app/jobs/sync_open_orders_job.rb
class SyncOpenOrdersJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: 5.minutes, attempts: 3
  
  def perform
    Rails.logger.info "Starting OpenOrders sync"
    # ... sync logic
    Rails.logger.info "Completed OpenOrders sync: #{count} records"
  end
end
```

**Error Handling**:
- `retry_on` provides automatic retries with backoff
- Failures are logged by Solid Queue
- Job dashboard shows execution history

**Alternatives Considered**:
- **whenever gem**: External cron management, adds complexity
- **sidekiq-scheduler**: Requires Redis, violates constitution
- **Manual cron job**: No retry logic, harder to monitor
- **rake task with cron**: No built-in error handling or monitoring

---

## 5. SQL Server Query Performance

### Decision: Use explicit column list with SELECT

**Rationale**: Explicit column list makes query intent clear, protects against view schema changes adding unwanted columns, and documents which fields we're syncing. Performance difference with SELECT * is negligible for <5,000 records.

**Query Approach**:

```sql
SELECT 
  SalesDoc, ItemNumber, CustName, SoldTo, ShipTo,
  Country, Plant, Material, MaterialDescription,
  OrderDate, RequestedDate, OrderQty, ConfirmQty,
  -- ... all 70+ columns explicitly listed
FROM vwZSDOrder_Advanced
ORDER BY OrderDate DESC
```

**Connection Pattern**:

```ruby
# app/services/sql_server_connector.rb
class SqlServerConnector
  def self.fetch_all_orders
    connection = establish_connection
    result = connection.execute(FETCH_QUERY)
    rows = result.to_a
    result.close
    connection.close
    rows
  rescue TinyTDS::Error => e
    Rails.logger.error "SQL Server connection failed: #{e.message}"
    raise
  end
  
  private
  
  def self.establish_connection
    config = Rails.configuration.database_configuration['sqlserver']
    TinyTDS::Client.new(
      host: config['host'],
      username: config['username'],
      password: config['password'],
      database: config['database'],
      timeout: config['timeout'] || 30
    )
  end
end
```

**Performance Considerations**:
- View query expected to complete in <10 seconds for <5,000 records
- No indexes needed (view is read-only, defined by DBAs)
- No pagination needed (dataset small enough to fetch in one query)
- ORDER BY OrderDate DESC ensures most recent orders first (helpful for troubleshooting)

**Alternatives Considered**:
- **SELECT ***: Simpler but risky if view schema changes, less documentation value
- **Pagination**: Unnecessary complexity for <5,000 records
- **Streaming results**: TinyTDS already streams, explicit streaming adds complexity
- **Connection pooling**: Not needed for single background job execution

---

## Technology Decisions Summary

| Decision | Choice | Key Rationale |
|----------|--------|---------------|
| SQL Server Adapter | TinyTDS (~> 2.1) | Standard, production-ready, minimal dependencies |
| Column Mapping | Explicit hash mapping | Clear, fail-fast, prevents silent errors |
| Batch Processing | insert_all, 500 records/batch | Efficient, built-in Rails, balanced memory/performance |
| Job Scheduling | Solid Queue recurring.yml | Constitution-compliant, automatic concurrency prevention |
| Query Strategy | Explicit column SELECT | Documents intent, protects against schema drift |
| Transaction Strategy | Fetch first, then truncate+insert | Preserves old data on fetch failure |
| Connection Timeout | 30 seconds | Balances responsiveness and network variability |
| Retry Strategy | 3 attempts, 5-minute wait | Handles transient failures, doesn't spam on persistent issues |

---

## Dependencies & Installation

### Gemfile Additions

```ruby
# SQL Server connectivity
gem 'tinytds', '~> 2.1'

# Optional: ActiveRecord adapter (provides additional features)
# gem 'activerecord-sqlserver-adapter', '~> 7.2'  # Only if needed for advanced features
```

### System Dependencies (Docker)

```dockerfile
# Add to Dockerfile
RUN apt-get update && apt-get install -y \
    freetds-dev \
    freetds-bin \
    && rm -rf /var/lib/apt/lists/*
```

### Configuration Files

1. **config/database.yml**: Add sqlserver connection config
2. **config/recurring.yml**: Add sync job schedule
3. **app/services/open_orders_importer.rb**: Column mapping configuration

---

## Implementation Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Connection failures during sync | Don't truncate data until fetch succeeds, retry with backoff |
| Column name mismatches | Explicit mapping fails loudly if column missing |
| Memory issues with large datasets | Batch processing at 500 records, stream from TinyTDS |
| Concurrent job executions | Solid Queue prevents automatically |
| SQL Server schema changes | Explicit column list documents expectations, fails on missing columns |
| Transaction timeout | Set 5-minute timeout, dataset size supports this |
| Credential exposure in logs | Mask passwords in error messages |

---

## Next Steps (Phase 1)

1. Create `data-model.md` with complete column mapping (all 70+ fields)
2. Create `quickstart.md` with setup and testing instructions
3. Update agent context with TinyTDS patterns
4. Re-check constitution compliance (expected: still compliant)

**Status**: Phase 0 complete ✅ - All research tasks resolved, ready for design phase.
