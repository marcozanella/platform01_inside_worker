# Feature Specification: SQL Server Sync Worker

**Feature Branch**: `002-sqlserver-sync-worker`  
**Created**: 2025-12-14  
**Status**: Draft  
**Input**: Background job to sync OpenOrder data from SAP SQL Server to local database

## Clarifications

### Session 2025-12-14

- Q: How often should the sync job run automatically? → A: Every 5 minutes (near real-time updates)
- Q: The vwZSDOrder_Advanced view may have different column names than the OpenOrder model fields. How should we handle column name mapping? → A: Manual mapping configuration with fallback - Define explicit mappings in code (e.g., SAPColumn → rails_attribute)
- Q: When a sync fails mid-process, should the old data remain in the database or should the table be left empty? → A: Keep old data intact - Don't truncate if fetch/import fails, users see last successful sync data
- Q: For large datasets, should the sync process records in batches or load everything into memory at once? → A: Batch insert with 500 records per batch (expected dataset size under 5,000 records)
- Q: Where should the SQL Server credentials be stored for production use? → A: Database configuration file (config/database.yml) - Simple approach, app runs in firewalled network

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Data Sync from SAP (Priority: P1)

The system automatically connects to SAP SQL Server on a recurring schedule, fetches all OpenOrder records from the vwZSDOrder_Advanced view, clears the local open_orders table, and imports the fresh data. This ensures the local database always has the latest SAP data.

**Why this priority**: Core functionality - without this, the OpenOrder view interface has no data to display. This is the primary purpose of the worker application.

**Independent Test**: Can be fully tested by triggering the sync job manually, verifying the open_orders table is truncated and repopulated with current SAP data, and confirms the last sync timestamp is updated.

**Acceptance Scenarios**:

1. **Given** the sync job is triggered, **When** it connects to SQL Server successfully, **Then** it fetches all records from vwZSDOrder_Advanced view
2. **Given** records are fetched from SAP successfully, **When** data import begins, **Then** the open_orders table is truncated in a transaction and new records are inserted
3. **Given** data is successfully imported, **When** the job completes, **Then** the last sync timestamp is updated
4. **Given** the job runs successfully, **When** viewing the OpenOrders interface, **Then** all fetched records are visible
5. **Given** a fetch or import fails, **When** the error occurs, **Then** the open_orders table is NOT truncated and old data remains visible

---

### User Story 2 - Scheduled Recurring Sync (Priority: P1)

The sync job runs automatically every 5 minutes without manual intervention, providing near real-time data updates from SAP.

**Why this priority**: Essential for keeping data fresh - manual sync is not sustainable for production use. 5-minute intervals ensure users see recent order updates quickly.

**Independent Test**: Verify the job runs automatically every 5 minutes, check logs confirm multiple successful executions, and observe that data is refreshed consistently.

**Acceptance Scenarios**:

1. **Given** a 5-minute recurring schedule is configured, **When** the scheduled time arrives, **Then** the sync job executes automatically
2. **Given** a sync is in progress, **When** the next 5-minute interval arrives, **Then** the system skips the new execution (no concurrent syncs)
3. **Given** the application restarts, **When** it initializes, **Then** the 5-minute schedule resumes from the next interval

---

### User Story 3 - Error Handling and Logging (Priority: P1)

When the sync job encounters errors (connection failures, authentication issues, query errors), it logs detailed error information and does not corrupt or partially update the local database.

**Why this priority**: Critical for reliability - prevents data corruption and enables troubleshooting when issues occur.

**Independent Test**: Simulate connection failure by providing wrong credentials or host, verify the job logs the error clearly, and confirm the open_orders table remains unchanged (not truncated if fetch fails).

**Acceptance Scenarios**:

1. **Given** SQL Server connection fails, **When** the job attempts to connect, **Then** it logs the connection error and exits gracefully without truncating local data
2. **Given** authentication fails, **When** credentials are rejected, **Then** it logs authentication failure with masked password and does not proceed
3. **Given** the SQL query fails, **When** fetching from vwZSDOrder_Advanced, **Then** it logs the query error and does not truncate local data
4. **Given** data import encounters an error mid-process, **When** the transaction fails, **Then** it rolls back the transaction and logs the error
5. **Given** any error occurs, **When** the job completes, **Then** the last sync timestamp is NOT updated

---

### User Story 4 - Sync Status Visibility (Priority: P2)

Administrators can view sync job status including last successful sync time, last error, and current sync progress through logs or the web interface.

**Why this priority**: Important for monitoring - allows admins to detect sync issues quickly, but the core sync functionality (P1) doesn't depend on this.

**Independent Test**: Run a sync job, check the logs show start/progress/completion messages, and verify the OpenOrders index page displays the last sync timestamp.

**Acceptance Scenarios**:

1. **Given** a sync job is running, **When** viewing application logs, **Then** progress messages indicate current status (connecting, fetching, importing)
2. **Given** a sync completed successfully, **When** viewing the OpenOrders interface, **Then** the last sync timestamp reflects the completion time
3. **Given** a sync failed, **When** viewing logs, **Then** the error details are visible with timestamp and error type

---

### Edge Cases

- What happens when SQL Server is temporarily unreachable during sync?
  - Job logs error, does not truncate local data, old data remains visible, retries on next scheduled run (5 minutes later)
  
- What happens if vwZSDOrder_Advanced view returns zero records?
  - Job logs warning, truncates open_orders table (intentional - SAP is source of truth), updates sync timestamp
  
- What happens if the view schema changes (new columns added/removed)?
  - Job attempts to map available columns, logs warnings for unmapped fields, continues with available data
  
- What happens if a sync takes longer than the scheduled interval?
  - Next scheduled execution is skipped (no concurrent syncs), job runs again at subsequent scheduled time
  
- What happens if the Rails application restarts during an active sync?
  - Job is interrupted, database transaction rolls back, next scheduled sync runs normally
  
- What happens with large datasets (10,000+ records)?
  - Job uses batch processing (500 records per batch) to avoid memory issues, logs progress every batch, completes successfully. With expected <5,000 records, this is not a concern.

- What happens if database connection pool is exhausted?
  - Job waits for available connection or times out with clear error message

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST connect to SQL Server at CASQL2.inxintl.com using provided credentials
- **FR-002**: System MUST fetch all records from the vwZSDOrder_Advanced view
- **FR-003**: System MUST truncate the open_orders table only after successfully fetching data from SQL Server (within the same transaction)
- **FR-004**: System MUST map SQL Server view columns to OpenOrder model attributes using explicit column mapping configuration defined in code
- **FR-005**: System MUST use database transactions to ensure atomic updates (all-or-nothing)
- **FR-006**: System MUST update the last sync timestamp only on successful completion
- **FR-007**: System MUST run every 5 minutes using Solid Queue recurring job configuration
- **FR-008**: System MUST log all sync attempts with timestamp, status, and record count
- **FR-009**: System MUST log errors with sufficient detail for troubleshooting (connection errors, SQL errors, data errors)
- **FR-010**: System MUST not run concurrent sync jobs (prevent overlapping executions)
- **FR-011**: System MUST handle SQL Server connection timeouts gracefully
- **FR-012**: System MUST handle authentication failures gracefully without exposing credentials in logs
- **FR-013**: System MUST validate data types when importing (handle nulls, dates, numbers appropriately)
- **FR-014**: System MUST rollback database transaction on any error during import
- **FR-015**: System MUST store SQL Server credentials in config/database.yml (sqlserver section)
- **FR-016**: System MUST process imports in batches of 500 records to optimize memory usage and performance

### Non-Functional Requirements

- **NFR-001**: Sync job SHOULD complete within 5 minutes for datasets up to 5,000 records (expected maximum)
- **NFR-002**: Job errors MUST be logged at ERROR level, successful completions at INFO level
- **NFR-003**: Credentials MUST NOT appear in plain text in logs (mask passwords)
- **NFR-004**: SQL Server connection timeout SHOULD be configurable (default: 30 seconds)
- **NFR-005**: Database transaction timeout SHOULD be configurable (default: 5 minutes)

### Key Entities

- **OpenOrder**: Existing model with 70+ fields (no schema changes required)
- **SyncJob**: Background job class that orchestrates the sync process
- **SqlServerConnection**: Service object that manages SQL Server connectivity
- **DataImporter**: Service object that handles data transformation and import with explicit column mapping configuration

### Dependencies

- **tinytds** gem: Ruby SQL Server adapter
- **activerecord-sqlserver-adapter** gem (optional): ActiveRecord adapter for SQL Server
- **Solid Queue**: Background job processing (already configured per constitution)
- **OpenOrder model**: Existing model with migration already applied
- **SQL Server access**: Network connectivity to CASQL2.inxintl.com (firewalled network)
- **Credentials**: Stored in config/database.yml - Host: CASQL2.inxintl.com, Username: zsdOrder8800, Password: 3~EmX~Kf$}, Database: vwZSDOrder_Advanced view

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sync job successfully connects to SQL Server and fetches records within 30 seconds
- **SC-002**: All 70+ fields from vwZSDOrder_Advanced are correctly mapped to OpenOrder attributes using explicit column mapping
- **SC-003**: Sync completes successfully for datasets up to 5,000 records within 5 minutes using batch processing (500 records/batch)
- **SC-004**: Sync job runs automatically on configured schedule without manual intervention
- **SC-005**: Zero data corruption events (failed syncs do not leave partial data)
- **SC-006**: All sync attempts (success and failure) are logged with sufficient detail for troubleshooting
- **SC-007**: Last sync timestamp visible in OpenOrders interface updates within 1 second of job completion
- **SC-008**: Connection errors are logged with clear error messages without exposing credentials
- **SC-009**: Sync job can be manually triggered for testing/troubleshooting purposes
- **SC-010**: System handles SQL Server downtime gracefully (logs error, retries on schedule)
