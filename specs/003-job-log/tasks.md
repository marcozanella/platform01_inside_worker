# Tasks: Job Execution Logging

**Feature Branch**: `003-job-log`  
**Input**: Design documents from `/specs/003-job-log/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No tests per constitution - manual validation only

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Exact file paths included in descriptions

---

## Phase 1: Setup

**Purpose**: Database schema and basic model structure

- [x] T001 Generate JobLog model using Rails generator: `bin/rails g model JobLog name:string:uniq status:integer:index`
- [x] T002 Generate JobLogDetail model using Rails generator: `bin/rails g model JobLogDetail job_log:references message:text`
- [x] T003 Edit migration db/migrate/YYYYMMDDHHMMSS_create_job_logs.rb to add NOT NULL constraints, default status=0, and created_at index

---

## Phase 2: Foundational

**Purpose**: Core models and database - MUST complete before any user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Edit migration db/migrate/YYYYMMDDHHMMSS_create_job_log_details.rb to add NOT NULL constraint on message and created_at index
- [x] T005 Run migrations: `bin/rails db:migrate`
- [x] T006 [P] Configure JobLog model in app/models/job_log.rb with enum, validations, and create_with_timestamp! class method
- [x] T007 [P] Configure JobLogDetail model in app/models/job_log_detail.rb with validations and default_scope ordering
- [x] T008 Verify models in Rails console: Create JobLog, add details, query by status

**Checkpoint**: Foundation ready - database schema exists, models functional

---

## Phase 3: User Story 1 - View Job Execution History (Priority: P1) 🎯 MVP

**Goal**: Administrators can view chronological list of job executions on root page with navigation to Open Orders and Mission Control

**Independent Test**: Navigate to root, see job log list with status indicators; click links to Open Orders and Mission Control

### Implementation for User Story 1

- [x] T009 [P] [US1] Generate JobLogsController: `bin/rails g controller JobLogs index show`
- [x] T010 [P] [US1] Edit config/routes.rb to set root to job_logs#index and add resources :job_logs, only: [:index, :show]
- [x] T011 [US1] Implement index action in app/controllers/job_logs_controller.rb with HTTP Basic Auth, pagination (25 per page)
- [x] T012 [US1] Create job logs index view in app/views/job_logs/index.html.erb with Tailwind styling, status badges, navigation buttons
- [x] T013 [US1] Add Open Orders link to index view (top right, gray button with document icon)
- [x] T014 [US1] Move Jobs Monitor button from Open Orders to Job Logs index view (blue button with clipboard icon)
- [x] T015 [US1] Remove Jobs Monitor button from app/views/open_orders/index.html.erb

**Checkpoint**: Root page displays job logs list with working navigation. Story 1 independently functional.

---

## Phase 4: User Story 2 - View Detailed Job Execution Log (Priority: P2)

**Goal**: Administrators can click any job log entry to see detailed chronological log messages

**Independent Test**: Click any job log from index, see detail page with all log messages in order

### Implementation for User Story 2

- [x] T016 [US2] Implement show action in app/controllers/job_logs_controller.rb to load JobLog with associated JobLogDetails
- [x] T017 [US2] Create job log show view in app/views/job_logs/show.html.erb with log messages in terminal-style display
- [x] T018 [US2] Add execution summary section to show view (started at, completed at, duration)
- [x] T019 [US2] Add back link to index from show view
- [x] T020 [US2] Test detail view navigation: Click log entry from index → see details → back button returns to index

**Checkpoint**: Detail view displays log messages chronologically. Story 2 independently functional.

---

## Phase 5: User Story 3 - Automatic Job Logging (Priority: P3)

**Goal**: Background jobs automatically create logs and capture execution details without manual intervention

**Independent Test**: Trigger job (manual or scheduled), verify JobLog created with timestamp name and status transitions recorded

### Implementation for User Story 3

- [x] T021 [US3] Add JobLog.create_with_timestamp! call at start of SyncOpenOrdersJob#perform in app/jobs/sync_open_orders_job.rb
- [x] T022 [US3] Add job_log.add_detail("Job started - SyncOpenOrdersJob") after JobLog creation
- [x] T023 [US3] Update job status to :processing after initialization: job_log.processing!
- [x] T024 [US3] Add log detail messages for SQL Server connection steps in sync job
- [x] T025 [US3] Add log detail messages for data fetch step with record count
- [x] T026 [US3] Update OpenOrdersImporter#import in app/services/open_orders_importer.rb to accept job_log parameter
- [x] T027 [US3] Add log detail messages in OpenOrdersImporter for truncate and batch import steps
- [x] T028 [US3] Add success transition at job end: job_log.success! with final statistics
- [x] T029 [US3] Update error handlers in sync job to call job_log.error! and add error details
- [x] T030 [US3] Test manual job trigger: `bin/rails sync:open_orders` → verify JobLog created with all details
- [ ] T031 [US3] Test automatic scheduled execution: wait for recurring job → verify new JobLog appears every 5 minutes
- [ ] T032 [US3] Test error scenario: break SQL Server connection → trigger job → verify status="error" and error message captured

**Checkpoint**: All jobs automatically log execution. Story 3 independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and documentation

- [x] T033 [P] Add helper method in app/helpers/job_logs_helper.rb for status badge formatting (extract from view)
- [x] T034 [P] Update README.md with Job Logging section explaining how to view logs and what information is captured
- [x] T035 [P] Verify pagination works correctly on job logs index with 30+ entries
- [x] T036 [P] Test timestamp collision handling: Create two logs in same second → verify suffix appended
- [x] T037 Review security: Verify HTTP Basic Auth applied to JobLogsController (same credentials as OpenOrders)
- [x] T038 Final validation: Navigate all pages (root → details → back, root → open orders → back, root → mission control)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T003) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T004-T008) completion
- **User Story 2 (Phase 4)**: Depends on Foundational (T004-T008) completion - can run parallel with US1 if desired
- **User Story 3 (Phase 5)**: Depends on Foundational (T004-T008) completion - can run parallel with US1/US2 if desired
- **Polish (Phase 6)**: Depends on US1, US2, US3 completion

### User Story Independence

- **US1 (View History)**: Standalone - requires only models from Foundational
- **US2 (View Details)**: Standalone - requires only models from Foundational + US1's controller
- **US3 (Auto Logging)**: Standalone - requires only models from Foundational + existing SyncOpenOrdersJob

### Task Dependencies Within Stories

**User Story 1**:
- T009-T010 (controller + routes) can run in parallel [P]
- T011 must complete before T012 (implement action before view uses it)
- T012-T015 sequential (view creation → add links → move button)

**User Story 2**:
- T016-T017 sequential (action before view)
- T018-T020 sequential (build view features progressively)

**User Story 3**:
- T021-T025 sequential (job modifications in order)
- T026-T027 together (modify service)
- T028-T029 sequential (success then error handling)
- T030-T032 can run in any order [P] (independent test scenarios)

**Polish**:
- T033-T036 can all run in parallel [P] (different concerns)
- T037-T038 must be last (final validation)

### Parallel Opportunities

**Within Setup** (all [P]):
```bash
# Can run simultaneously:
T001: Generate JobLog model
T002: Generate JobLogDetail model
T003: Edit job_logs migration
```

**Within Foundational** (some [P]):
```bash
# Can run simultaneously after T005:
T006: Configure JobLog model
T007: Configure JobLogDetail model
```

**Across User Stories** (after Foundational):
```bash
# Can run simultaneously:
Developer A: T009-T015 (User Story 1)
Developer B: T016-T020 (User Story 2)
Developer C: T021-T032 (User Story 3)
```

**Within Polish** (all [P]):
```bash
# Can run simultaneously:
T033: Helper method extraction
T034: README updates
T035: Pagination testing
T036: Collision testing
```

---

## Parallel Example: All User Stories

Once Foundational phase (T004-T008) is complete, three developers can work independently:

```bash
# Developer A - User Story 1 (View History)
Tasks: T009 → T010 → T011 → T012 → T013 → T014 → T015
Independent test: Navigate to root, see logs, click navigation
Deliverable: Job log list page with navigation

# Developer B - User Story 2 (View Details)  
Tasks: T016 → T017 → T018 → T019 → T020
Independent test: Click any log, see details, click back
Deliverable: Job log detail page

# Developer C - User Story 3 (Auto Logging)
Tasks: T021 → T022 → T023 → T024 → T025 → T026 → T027 → T028 → T029 → T030 → T031 → T032
Independent test: Trigger job, verify log created automatically
Deliverable: Jobs automatically log execution
```

Each story can be tested and deployed independently. Story 1 alone provides MVP value (can see job history).

---

## Implementation Strategy

### MVP First (Recommended - User Story 1 Only)

1. **Phase 1**: Setup (T001-T003) → ~10 minutes
2. **Phase 2**: Foundational (T004-T008) → ~30 minutes
3. **Phase 3**: User Story 1 (T009-T015) → ~60 minutes
4. **STOP and VALIDATE**: Navigate to root, see empty log list, verify navigation buttons work
5. **Manual data**: Create 2-3 JobLog entries in console to test list display
6. **MVP COMPLETE**: Admin can view job execution history

**Total MVP time**: ~2 hours

### Full Feature (All Stories)

1. Complete MVP (Phases 1-3)
2. Add User Story 2 (T016-T020) → ~30 minutes → Test detail view independently
3. Add User Story 3 (T021-T032) → ~60 minutes → Test automatic logging
4. Polish (T033-T038) → ~30 minutes
5. **FEATURE COMPLETE**: Full job logging system operational

**Total time**: ~4 hours

### Parallel Team Strategy

With 3 developers (after Foundational phase):

1. **Setup + Foundational together** (~40 minutes)
2. **Then split**:
   - Dev A: User Story 1 (60 min) → Deploy MVP
   - Dev B: User Story 2 (30 min) → Integrate
   - Dev C: User Story 3 (60 min) → Integrate
3. **Polish together** (30 min)

**Total time with parallelization**: ~2.5 hours

---

## Validation Checklist

### After User Story 1
- ✅ Root page loads and displays "No job logs yet" message
- ✅ Open Orders link navigates to /open_orders
- ✅ Jobs Monitor button navigates to /jobs (Mission Control)
- ✅ Manually created JobLog entries display with correct status badges
- ✅ Pagination appears when 26+ logs exist

### After User Story 2
- ✅ Clicking any log entry navigates to detail page
- ✅ Detail page shows all JobLogDetail messages in chronological order
- ✅ Execution summary displays start time, end time, duration
- ✅ Back button returns to index page

### After User Story 3
- ✅ Manual sync (`bin/rails sync:open_orders`) creates JobLog with timestamp name
- ✅ Job status transitions: new → processing → success
- ✅ Log details captured for each major step (connect, fetch, import, complete)
- ✅ Batch import messages show progress (Batch 1/4, 2/4, etc.)
- ✅ Error scenario (broken connection) creates log with status="error"
- ✅ Recurring job creates new log every 5 minutes automatically
- ✅ Each automatic execution has unique timestamp name

### After Polish
- ✅ README.md explains job logging feature
- ✅ Pagination tested with 50+ logs
- ✅ Collision handling tested (same-second logs get _1 suffix)
- ✅ HTTP Basic Auth required for /job_logs routes
- ✅ All navigation paths work correctly

---

## Notes

- **No tests**: Per constitution, manual validation only
- **[P] marker**: Tasks that can run in parallel (different files/concerns)
- **[Story] label**: Maps task to user story for traceability
- **File paths**: All paths absolute from repository root
- **Checkpoints**: Stop and validate after each user story phase
- **Independence**: Each user story should work standalone before integrating

**Ready for implementation!** Start with T001 and proceed sequentially or parallelize as team capacity allows.
