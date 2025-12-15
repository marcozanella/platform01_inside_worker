# Research & Design Decisions: Job Execution Logging

**Feature**: 003-job-log | **Date**: 2025-12-15

## Overview

This document captures research findings and design decisions for the Job Execution Logging feature. All NEEDS CLARIFICATION items from the Technical Context have been resolved.

## Research Areas

### 1. JobLog Timestamp Uniqueness Strategy

**Question**: How to ensure unique JobLog names when using YYYYMMDDhhmmss format (second-level granularity)?

**Research Findings**:
- Rails recurring jobs via Solid Queue run on schedule (every 5 minutes for SyncOpenOrdersJob)
- Collision risk is minimal but not zero (manual triggers could overlap)
- Rails convention: Add a sequence number suffix if collision detected

**Decision**: Use YYYYMMDDhhmmss format as base, append incremental suffix (_1, _2, etc.) on collision
- **Rationale**: Simple, readable, follows Rails conventions for handling uniqueness
- **Implementation**: In job initializer, attempt to create with timestamp; if unique constraint fails, append suffix and retry
- **Alternative Considered**: Use UUID - rejected because not human-readable and doesn't convey execution time

### 2. Status Field Implementation

**Question**: Should status be database enum, Rails enum, or plain string?

**Research Findings**:
- Rails enum provides type safety and helper methods (e.g., `job_log.success?`, `job_log.error!`)
- Database constraint adds redundant validation layer
- Rails 8 enum syntax: `enum status: { new: 0, processing: 1, error: 2, success: 3 }`

**Decision**: Use Rails enum with integer backing
- **Rationale**: Clean API, type-safe, follows Rails conventions, provides helpful query scopes
- **Implementation**: `enum :status, { new: 0, processing: 1, error: 2, success: 3 }`
- **Alternative Considered**: String column - rejected because no type safety and wastes storage

### 3. Log Detail Message Storage

**Question**: Store log details as individual records vs. JSON array in JobLog?

**Research Findings**:
- Separate JobLogDetail records allow easy pagination and incremental writes
- JSON array requires reading entire log, no atomic updates
- Disk space is not a constraint (each detail ~100-500 bytes, 20 details = ~10KB per log)

**Decision**: Separate JobLogDetail model with one-to-many relationship
- **Rationale**: Follows Rails conventions (normalized data), supports incremental logging, easy to query/filter
- **Implementation**: Standard `has_many :job_log_details, dependent: :destroy` association
- **Alternative Considered**: JSON column - rejected because complex querying, no atomicity, not Rails-idiomatic

### 4. Logging Integration Pattern

**Question**: How should SyncOpenOrdersJob integrate with logging?

**Research Findings**:
- Option A: Job creates JobLog explicitly, passes to service methods
- Option B: Service methods create/update JobLog via callback
- Option C: Separate logging concern/module mixed into jobs

**Decision**: Option A - Explicit JobLog creation at job start, passed to service methods
- **Rationale**: Clear control flow, easy to test, no magic, follows Rails "explicit over implicit" principle
- **Implementation**: 
  ```ruby
  def perform
    job_log = JobLog.create!(name: timestamp, status: :new)
    job_log.processing!
    # ... work with job_log
    job_log.success!
  rescue => e
    job_log&.error!
    job_log&.add_detail("Error: #{e.message}")
    raise
  end
  ```
- **Alternative Considered**: Concern module - rejected because adds abstraction layer without clear benefit for single job type

### 5. Pagination Strategy

**Question**: What pagination approach for job log index?

**Research Findings**:
- Kaminari gem already in Gemfile (used for OpenOrders)
- Expected scale: ~300 logs/day * 30 days = 9,000 entries/month
- Default page size: 25 entries (standard Rails practice)

**Decision**: Use existing Kaminari pagination with 25 entries per page
- **Rationale**: Already available, consistent with OpenOrders pagination, proven pattern
- **Implementation**: `@job_logs = JobLog.order(created_at: :desc).page(params[:page])`
- **Alternative Considered**: Custom pagination - rejected because Kaminari already integrated

### 6. Performance Considerations

**Question**: Will logging impact job execution performance?

**Research Findings**:
- JobLog creation: ~5ms (single INSERT)
- JobLogDetail creation: ~3ms per detail, 20 details = ~60ms total
- Total overhead: ~65ms per job execution
- Current job runtime: 10-30 seconds (data fetch dominates)

**Decision**: Synchronous logging is acceptable, no async queue needed
- **Rationale**: <1% overhead, simpler implementation, immediate visibility
- **Implementation**: Direct ActiveRecord creates/updates within job transaction
- **Alternative Considered**: Async logging via separate job - rejected because unnecessary complexity, delays visibility

### 7. Root Route Change Impact

**Question**: What happens to existing root route to OpenOrders?

**Research Findings**:
- Current root: `root "open_orders#index"`
- Change to: `root "job_logs#index"`
- OpenOrders accessible via link on JobLogs index
- HTTP Basic Auth already in place for OpenOrdersController

**Decision**: Change root to JobLogs, add link to OpenOrders on JobLogs index
- **Rationale**: Aligns with spec requirement, job monitoring is primary admin activity
- **Implementation**: Update routes.rb, add nav link in job_logs/index.html.erb
- **Security Note**: JobLogsController should inherit same authentication as OpenOrdersController

## Best Practices Applied

### Rails 8 Conventions
- Use generators: `rails g model JobLog`, `rails g model JobLogDetail`
- Standard associations: `has_many`, `belongs_to`
- RESTful routes: `resources :job_logs, only: [:index, :show]`
- Enum for status field
- Kaminari for pagination

### Simplicity Principles
- No complex async logging
- No caching layer initially
- Standard ActiveRecord queries
- Minimal controller logic
- Basic Tailwind-styled views

### Background Job Integration
- Explicit log creation at job start
- Status transitions follow job lifecycle
- Error handling captures to log before re-raising
- Idempotent: Re-running creates new log, doesn't corrupt existing

## Summary

All technical decisions align with Rails 8 conventions and constitution principles. No external dependencies required beyond existing stack (Kaminari already present). Implementation follows "simplicity over optimization" with standard ActiveRecord patterns.

**Key Decisions**:
1. YYYYMMDDhhmmss timestamp with collision suffix
2. Rails enum for status field
3. Separate JobLogDetail model (one-to-many)
4. Explicit logging pattern in jobs
5. Kaminari pagination (25 per page)
6. Synchronous logging (acceptable overhead)
7. Root route to JobLogs with link to OpenOrders
