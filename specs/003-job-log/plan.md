# Implementation Plan: Job Execution Logging

**Branch**: `003-job-log` | **Date**: 2025-12-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-job-log/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add comprehensive job execution logging system with JobLog and JobLogDetail models to track all background job executions. Users can view job history on the root page, drill into detailed execution logs, and automatically capture execution details including status transitions, error messages, and processing statistics. Root route changes to JobLog index with navigation links to Open Orders and Mission Control.

## Technical Context

**Language/Version**: Ruby 3.3.5 / Rails 8.1.1 (per constitution)  
**Primary Dependencies**: Standard Rails 8 stack (Solid Queue, Tailwind CSS) - no additional gems required  
**Storage**: SQLite3 (primary database for JobLog/JobLogDetail models) - per constitution  
**Testing**: None (per constitution - manual validation only)  
**Target Platform**: Linux server (Docker via Kamal) - per constitution  
**Project Type**: Rails worker application (background job processing)  
**Performance Goals**: Load job log index page in <2 seconds with 100+ log entries; detail view loads in <1 second  
**Constraints**: Must not impact existing SyncOpenOrdersJob performance; log writes should be asynchronous where possible  
**Scale/Scope**: Expect 288 job logs per day (one every 5 minutes), ~8,640 per month; each log may have 5-20 detail messages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Phase 0 Check (Pre-Research)**: ✅ PASSED
- [x] **Rails Conventions First**: Design follows Rails 8 conventions (generators for models, standard associations, RESTful routes, Rails views with Tailwind)
- [x] **Background Job Architecture**: Feature enhances existing background job architecture by adding logging; does not change job execution patterns
- [x] **Simplicity Over Optimization**: Simple ActiveRecord models with standard associations; basic pagination; no complex streaming or caching initially
- [x] **Admin-Only Operations**: Feature is admin-only (viewing job logs, no end-user interaction); uses simple Rails views with Tailwind styling
- [x] **Modern Rails Stack**: Uses existing Solid Queue, standard Rails views, Tailwind CSS; no new dependencies required

**Phase 1 Check (Post-Design)**: ✅ PASSED
- [x] **Rails Conventions First**: Implementation uses standard Rails generators, enum for status, has_many/belongs_to associations, RESTful routes, Kaminari pagination
- [x] **Background Job Architecture**: JobLog integration is explicit and simple; jobs remain idempotent; logging doesn't affect retry behavior
- [x] **Simplicity Over Optimization**: Synchronous logging (<1% overhead), standard indexes, no caching layer, straightforward ActiveRecord queries
- [x] **Admin-Only Operations**: All views admin-only with HTTP Basic Auth; simple Tailwind-styled interfaces; no complex UX
- [x] **Modern Rails Stack**: Zero new dependencies; uses existing Kaminari, Tailwind CSS, standard SQLite3 primary database

*No violations in either phase - all principles align with implementation.*

## Project Structure

### Documentation (this feature)

```text
specs/003-job-log/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/
├── models/
│   ├── job_log.rb                    # NEW: JobLog model (name, status, timestamps)
│   └── job_log_detail.rb             # NEW: JobLogDetail model (message, job_log_id, timestamps)
├── jobs/
│   └── sync_open_orders_job.rb       # MODIFIED: Add logging integration
├── controllers/
│   └── job_logs_controller.rb        # NEW: index and show actions
└── views/
    ├── job_logs/
    │   ├── index.html.erb             # NEW: Job log list with status indicators
    │   └── show.html.erb              # NEW: Job log detail messages
    └── open_orders/
        └── index.html.erb             # MODIFIED: Remove Jobs Monitor button

config/
├── routes.rb                          # MODIFIED: Change root, add job_logs routes
└── database.yml                       # NO CHANGE: Uses existing primary database

db/
└── migrate/
    ├── YYYYMMDDHHMMSS_create_job_logs.rb         # NEW: Migration for job_logs table
    └── YYYYMMDDHHMMSS_create_job_log_details.rb  # NEW: Migration for job_log_details table

lib/
└── tasks/
    └── sync.rake                      # MODIFIED: Update manual sync to use logging (optional)
```

**Structure Decision**: Standard Rails 8 structure with two new models, one new controller, and minimal view changes. JobLog and JobLogDetail follow Rails naming conventions (singular models, plural tables). Controller follows RESTful conventions (index/show only). Integration with existing SyncOpenOrdersJob via standard ActiveRecord updates.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations - section not applicable.*
