# Data Model: Job Execution Logging

**Feature**: 003-job-log | **Date**: 2025-12-15

## Entity-Relationship Overview

```
JobLog (1) ----< (many) JobLogDetail
```

**Cardinality**: One JobLog has many JobLogDetails; each JobLogDetail belongs to one JobLog.

## Entity Definitions

### JobLog

Represents a single execution of a background job.

**Attributes**:
- `id` (integer, primary key): Auto-incrementing identifier
- `name` (string, not null, indexed, unique): Timestamp identifier in YYYYMMDDhhmmss format (e.g., "20251215143022")
- `status` (integer, not null, default: 0): Current execution state (enum: pending=0, processing=1, error=2, success=3)
- `created_at` (datetime, not null): When the log entry was created
- `updated_at` (datetime, not null): When the log entry was last modified

**Relationships**:
- `has_many :job_log_details, dependent: :destroy` - Associated log detail messages

**Indexes**:
- `name` (unique): Ensures unique timestamp identifiers, supports lookup by name
- `status`: Supports filtering by status (e.g., find all errors)
- `created_at`: Supports chronological sorting (most recent first)

**Validations**:
- `presence: true` for name and status
- `uniqueness: true` for name
- `format` for name: `/\A\d{14}(_\d+)?\z/` (YYYYMMDDhhmmss with optional suffix)

**Enum Definition**:
```ruby
enum :status, { pending: 0, processing: 1, error: 2, success: 3 }
```

**Scopes** (provided by enum):
- `JobLog.pending` - All logs with status "pending"
- `JobLog.processing` - All logs with status "processing"
- `JobLog.error` - All logs with status "error"
- `JobLog.success` - All logs with status "success"

**Helper Methods**:
- `#pending?`, `#processing?`, `#error?`, `#success?` - Status checks (enum methods)
- `#processing!`, `#error!`, `#success!` - Status updates (enum methods)
- `#add_detail(message)` - Create new JobLogDetail with message

---

### JobLogDetail

Represents individual log messages within a job execution.

**Attributes**:
- `id` (integer, primary key): Auto-incrementing identifier
- `job_log_id` (integer, not null, indexed, foreign key): Reference to parent JobLog
- `message` (text, not null): Descriptive log message (e.g., "Connected to SQL Server", "Imported 1,523 records")
- `created_at` (datetime, not null): When this log entry was recorded
- `updated_at` (datetime, not null): Standard Rails timestamp (rarely used for logs)

**Relationships**:
- `belongs_to :job_log` - Parent job execution log

**Indexes**:
- `job_log_id`: Supports efficient queries for all details of a given log
- `created_at`: Supports chronological ordering within a log

**Validations**:
- `presence: true` for job_log and message
- `length: { maximum: 5000 }` for message (prevent excessive message sizes)

**Default Scope**:
```ruby
default_scope { order(created_at: :asc) }
```
(Orders details chronologically within a log)

---

## Migration Files

### CreateJobLogs Migration

```ruby
class CreateJobLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :job_logs do |t|
      t.string :name, null: false, index: { unique: true }
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :job_logs, :status
    add_index :job_logs, :created_at
  end
end
```

### CreateJobLogDetails Migration

```ruby
class CreateJobLogDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :job_log_details do |t|
      t.references :job_log, null: false, foreign_key: true, index: true
      t.text :message, null: false
      t.timestamps
    end

    add_index :job_log_details, :created_at
  end
end
```

---

## Database Schema (SQLite3)

```sql
-- job_logs table
CREATE TABLE job_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE (name)
);

CREATE INDEX index_job_logs_on_name ON job_logs(name);
CREATE INDEX index_job_logs_on_status ON job_logs(status);
CREATE INDEX index_job_logs_on_created_at ON job_logs(created_at);

-- job_log_details table
CREATE TABLE job_log_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_log_id INTEGER NOT NULL,
  message TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (job_log_id) REFERENCES job_logs(id)
);

CREATE INDEX index_job_log_details_on_job_log_id ON job_log_details(job_log_id);
CREATE INDEX index_job_log_details_on_created_at ON job_log_details(created_at);
```

---

## Sample Data

### JobLog Examples

```ruby
# Successful sync job
JobLog.create!(
  name: "20251215143022",
  status: :success,
  created_at: Time.parse("2025-12-15 14:30:22"),
  updated_at: Time.parse("2025-12-15 14:30:45")
)

# Failed sync job
JobLog.create!(
  name: "20251215144022",
  status: :error,
  created_at: Time.parse("2025-12-15 14:40:22"),
  updated_at: Time.parse("2025-12-15 14:40:35")
)

# Currently running job
JobLog.create!(
  name: "20251215145022",
  status: :processing,
  created_at: Time.parse("2025-12-15 14:50:22"),
  updated_at: Time.parse("2025-12-15 14:50:25")
)

# Collision example (manual trigger during scheduled run)
JobLog.create!(
  name: "20251215143022_1",
  status: :success,
  created_at: Time.parse("2025-12-15 14:30:22"),
  updated_at: Time.parse("2025-12-15 14:30:50")
)
```

### JobLogDetail Examples

```ruby
job_log = JobLog.find_by(name: "20251215143022")

# Successful execution details
job_log.job_log_details.create!([
  { message: "Job started - SyncOpenOrdersJob", created_at: Time.parse("2025-12-15 14:30:22") },
  { message: "Connecting to SQL Server CASQL2.inxintl.com...", created_at: Time.parse("2025-12-15 14:30:23") },
  { message: "Connected successfully", created_at: Time.parse("2025-12-15 14:30:24") },
  { message: "Fetching records from vwZSDOrder_Advanced...", created_at: Time.parse("2025-12-15 14:30:25") },
  { message: "Fetched 1,523 records", created_at: Time.parse("2025-12-15 14:30:35") },
  { message: "Truncating existing open_orders table...", created_at: Time.parse("2025-12-15 14:30:36") },
  { message: "Importing records in batches of 500...", created_at: Time.parse("2025-12-15 14:30:37") },
  { message: "Batch 1/4 imported (500 records)", created_at: Time.parse("2025-12-15 14:30:39") },
  { message: "Batch 2/4 imported (500 records)", created_at: Time.parse("2025-12-15 14:30:41") },
  { message: "Batch 3/4 imported (500 records)", created_at: Time.parse("2025-12-15 14:30:43") },
  { message: "Batch 4/4 imported (23 records)", created_at: Time.parse("2025-12-15 14:30:44") },
  { message: "Job completed successfully - Total: 1,523 records in 23 seconds", created_at: Time.parse("2025-12-15 14:30:45") }
])

# Failed execution details
job_log_error = JobLog.find_by(name: "20251215144022")
job_log_error.job_log_details.create!([
  { message: "Job started - SyncOpenOrdersJob", created_at: Time.parse("2025-12-15 14:40:22") },
  { message: "Connecting to SQL Server CASQL2.inxintl.com...", created_at: Time.parse("2025-12-15 14:40:23") },
  { message: "ERROR: Connection failed - TinyTDS::Error: Login failed for user 'zsdOrder8800'", created_at: Time.parse("2025-12-15 14:40:35") }
])
```

---

## Query Patterns

### Common Queries

```ruby
# Get all logs, most recent first (for index page)
JobLog.order(created_at: :desc).page(params[:page])

# Get logs by status
JobLog.error.order(created_at: :desc)
JobLog.success.where("created_at > ?", 1.day.ago)

# Get specific log with details
job_log = JobLog.find(params[:id])
details = job_log.job_log_details # Already ordered by created_at

# Count logs by status (for dashboard)
{
  total: JobLog.count,
  success: JobLog.success.count,
  error: JobLog.error.count,
  processing: JobLog.processing.count
}

# Find latest execution
JobLog.order(created_at: :desc).first

# Create log with collision handling
def self.create_with_unique_name(timestamp)
  name = timestamp
  suffix = 0
  loop do
    begin
      return create!(name: name, status: :new)
    rescue ActiveRecord::RecordNotUnique
      suffix += 1
      name = "#{timestamp}_#{suffix}"
    end
  end
end
```

---

## Performance Considerations

### Index Strategy
- **name (unique)**: Prevents duplicates, supports fast lookups
- **status**: Enables fast filtering (e.g., show all errors)
- **created_at**: Optimizes chronological sorting
- **job_log_id**: Foreign key index for efficient joins

### Expected Data Volume
- **JobLogs**: ~9,000 per month (288/day at 5-minute intervals)
- **JobLogDetails**: ~180,000 per month (20 details per log average)
- **Total storage**: ~50MB per month at current scale
- **Query performance**: Indexes keep queries <50ms even at 100K+ records

### Optimization Opportunities (Future)
- Archive logs older than 90 days (manual or automated)
- Add composite index on (status, created_at) if filtering by status becomes common
- Consider partitioning if volume exceeds 1M records

---

## Alignment with Specification

| Requirement | Implementation |
|-------------|----------------|
| FR-001: JobLog model with name, status, timestamps | ✅ Implemented with Rails conventions |
| FR-002: JobLogDetail with message, job_log reference | ✅ One-to-many association via belongs_to |
| FR-003: YYYYMMDDhhmmss timestamp format | ✅ Enforced via validation, collision handling via suffix |
| FR-014: Timestamps for each detail | ✅ created_at automatically tracked |
| FR-015: Unique names with collision mechanism | ✅ Unique index + suffix pattern |

All data model requirements satisfied using standard Rails conventions and ActiveRecord features.
