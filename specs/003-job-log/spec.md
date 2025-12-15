# Feature Specification: Job Execution Logging

**Feature Branch**: `003-job-log`  
**Created**: 2025-12-15  
**Status**: Draft  
**Input**: User description: "Log table feature. Add a JobLog model with name field, a status (new-processing-error-success); and a JobLogDetail model referenced to JobLog. One JobLog to many JobLogDetail. When the job is triggered, a JobLog is created, it name is a timestamp (YYYYMMDDhhmmss). Add log messages during the process of the job to create-update in the JobLogDetail, so the user can go back and see what was wrong or is all was ok. Change the root to the JobLog index page. Move the Jobs Monitor button to the JobLog index page. Add a Link to the OpenOrder index view, on top of the JobLog index view."

## User Scenarios & Testing

### User Story 1 - View Job Execution History (Priority: P1)

As a system administrator, I need to view a chronological list of all job executions to quickly identify when jobs ran and their overall success/failure status.

**Why this priority**: This is the foundation of the logging system - users must be able to see job execution history before they can drill into details. Without this view, the feature provides no value.

**Independent Test**: Can be fully tested by navigating to the root page and verifying that a list of job logs displays with timestamp names and status indicators. Delivers immediate value by showing job execution history.

**Acceptance Scenarios**:

1. **Given** I navigate to the application root, **When** the page loads, **Then** I see a list of all job executions sorted by most recent first
2. **Given** I am viewing the job log list, **When** I look at each entry, **Then** I can see the timestamp name (YYYYMMDDhhmmss format) and current status (new, processing, error, success)
3. **Given** I am on the job log index page, **When** I need to view open orders, **Then** I see a clearly labeled link to the Open Orders page at the top
4. **Given** I am on the job log index page, **When** I need to access job monitoring tools, **Then** I see a Jobs Monitor button that takes me to Mission Control

---

### User Story 2 - View Detailed Job Execution Log (Priority: P2)

As a system administrator investigating a job failure, I need to view detailed log messages for a specific job execution to understand what went wrong and at what step.

**Why this priority**: Once users can see job history (P1), they need to investigate specific executions. This provides the diagnostic capability that makes the logging system useful.

**Independent Test**: Can be fully tested by clicking on any job log entry and verifying that detailed log messages display chronologically. Delivers value by enabling troubleshooting and debugging.

**Acceptance Scenarios**:

1. **Given** I am viewing the job log list, **When** I click on a specific job log entry, **Then** I see all associated log detail messages for that execution
2. **Given** I am viewing job log details, **When** log messages were created during execution, **Then** I see them in chronological order showing the progression of the job
3. **Given** I am viewing job log details for a failed job, **When** an error occurred, **Then** I can identify the specific step that failed and the error message
4. **Given** I am viewing job log details for a successful job, **When** the job completed normally, **Then** I can see all steps completed successfully with relevant statistics (e.g., records processed)

---

### User Story 3 - Automatic Job Logging (Priority: P3)

As a system, I need to automatically create job logs and capture execution details whenever a background job runs, so administrators have complete audit trails without manual intervention.

**Why this priority**: This enables the automatic population of the logging system. While critical for production use, it depends on P1 and P2 being in place to display the logged information.

**Independent Test**: Can be fully tested by triggering a job execution (manually or via schedule) and verifying that a new JobLog entry is created with timestamp name and that log details are captured throughout execution. Delivers value by providing automatic audit trails.

**Acceptance Scenarios**:

1. **Given** a background job is triggered, **When** execution starts, **Then** a new JobLog record is created with name in YYYYMMDDhhmmss format and status "new"
2. **Given** a job has started executing, **When** the job begins processing, **Then** the JobLog status updates to "processing"
3. **Given** a job is processing, **When** significant steps occur (e.g., connection established, data fetched, records imported), **Then** JobLogDetail entries are created or updated with descriptive messages
4. **Given** a job completes successfully, **When** all operations finish without errors, **Then** the JobLog status updates to "success" and final statistics are logged
5. **Given** a job encounters an error, **When** an exception or failure occurs, **Then** the JobLog status updates to "error" and the error details are captured in JobLogDetail
6. **Given** a job is running, **When** it needs to log information, **Then** log messages include timestamps and sufficient context to understand what happened

---

### Edge Cases

- What happens when multiple jobs run simultaneously? Each should have its own independent JobLog with unique timestamp names.
- How does the system handle very long-running jobs? The status should update from "new" to "processing" immediately, and log details should be written incrementally (not batched until completion).
- What happens if a job crashes unexpectedly? Jobs stuck in "processing" status for extended periods indicate crashes or hangs.
- What happens if two jobs start in the same second? The timestamp format (YYYYMMDDhhmmss) provides second-level granularity; use milliseconds or sequence numbers if necessary to ensure uniqueness.
- How many log entries should be retained? Assumption: No automatic pruning initially; administrators can manually delete old logs as needed.
- What if log details become very large? Each detail message should be a separate record to allow pagination and incremental loading.

## Requirements

### Functional Requirements

- **FR-001**: System MUST provide a JobLog model with name field (string), status field (enum: new, processing, error, success), and timestamps
- **FR-002**: System MUST provide a JobLogDetail model with a message field (text) and reference to JobLog (one-to-many relationship)
- **FR-003**: System MUST generate JobLog names using timestamp format YYYYMMDDhhmmss when jobs are triggered
- **FR-004**: System MUST create a JobLog record with status "new" when a background job execution begins
- **FR-005**: System MUST update JobLog status to "processing" when job execution starts actively working
- **FR-006**: System MUST update JobLog status to "success" when job execution completes without errors
- **FR-007**: System MUST update JobLog status to "error" when job execution encounters failures
- **FR-008**: System MUST create JobLogDetail records with descriptive messages during job execution for significant steps
- **FR-009**: System MUST provide a web interface displaying all JobLog entries in reverse chronological order (most recent first)
- **FR-010**: System MUST allow users to view all JobLogDetail messages for a selected JobLog entry
- **FR-011**: System MUST set the application root path to the JobLog index page
- **FR-012**: System MUST display a "Jobs Monitor" button on the JobLog index page linking to Mission Control
- **FR-013**: System MUST display a link to the Open Orders index page at the top of the JobLog index page
- **FR-014**: System MUST include timestamps for each JobLogDetail message to track progression
- **FR-015**: JobLog names MUST be unique or have mechanism to handle duplicate timestamps

### Key Entities

- **JobLog**: Represents a single execution of a background job
  - name: Timestamp identifier (YYYYMMDDhhmmss format)
  - status: Current state of execution (new, processing, error, success)
  - created_at: When the log was created
  - updated_at: When the log was last modified
  - Relationship: has_many JobLogDetail records

- **JobLogDetail**: Represents individual log messages within a job execution
  - job_log_id: Reference to parent JobLog
  - message: Descriptive text of what occurred
  - created_at: When this log entry was recorded
  - Relationship: belongs_to JobLog

## Success Criteria

### Measurable Outcomes

- **SC-001**: Administrators can view complete job execution history on the application homepage within 2 seconds of page load
- **SC-002**: Users can identify failed job executions at a glance by visual status indicators without clicking into details
- **SC-003**: Administrators can drill into any job execution and view detailed log messages in under 3 clicks
- **SC-004**: 100% of background job executions automatically create log entries without manual intervention
- **SC-005**: Log detail messages provide sufficient information to diagnose failures without needing to access server logs or database directly
- **SC-006**: Users can navigate from job logs to open orders and to Mission Control within 1 click from the main page
- **SC-007**: System handles concurrent job executions by maintaining separate, independent log entries for each execution

## Assumptions

- The existing SyncOpenOrdersJob will be modified to integrate with the logging system
- Log retention is manual initially; no automatic purging of old logs
- Timestamp format (YYYYMMDDhhmmss) provides sufficient uniqueness for job execution identification in typical use cases
- Standard Rails flash messages or similar will indicate navigation changes (e.g., "viewing job log details")
- Job log index will use standard pagination if the number of logs grows large (assumption: paginate after 50+ entries)
- Log detail messages will be text-based; no support for structured JSON logging initially
- Only background jobs (not all application events) will be logged via this system
