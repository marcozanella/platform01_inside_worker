# Tasks: SQL Server Sync Worker

**Feature**: 002-sqlserver-sync-worker  
**Branch**: `002-sqlserver-sync-worker`  
**Date**: 2025-12-14  

**Input**: Design documents from `/specs/002-sqlserver-sync-worker/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: This project has NO TESTS per constitution (Simplicity Over Optimization) - manual validation only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- File paths are absolute from repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup

- [X] T001 Add tinytds gem (~> 2.1) to Gemfile
- [X] T002 Add FreeTDS system dependencies to Dockerfile (freetds-dev freetds-bin via apt-get)
- [X] T003 Run bundle install to install tinytds gem

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Configure SQL Server connection in config/database.yml (host: CASQL2.inxintl.com, username: zsdOrder8800, password: 3~EmX~Kf$}, database: ProcessStatus, timeout: 30)
- [X] T005 [P] Create SqlServerConnector service in app/services/sql_server_connector.rb with TinyTDS client initialization, execute method, connection cleanup, and error handling
- [X] T006 [P] Create OpenOrdersImporter service in app/services/open_orders_importer.rb with COLUMN_MAPPING constant (67 fields mapped from SQL Server to Rails), batch processing (500 records), transaction handling, and type conversion logic
- [X] T007 Verify SQL Server connection works by running test script from quickstart.md (bin/rails runner with SqlServerConnector)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Automatic Data Sync from SAP (Priority: P1) 🎯 MVP

**Goal**: System automatically connects to SAP SQL Server, fetches all OpenOrder records from vwZSDOrder_Advanced view, clears local open_orders table, and imports fresh data with explicit column mapping

**Independent Test**: Trigger sync job manually via rake task, verify open_orders table is truncated and repopulated with current SAP data, confirm last sync timestamp updates

### Implementation for User Story 1

- [X] T008 [US1] Create SyncOpenOrdersJob in app/jobs/sync_open_orders_job.rb using Rails generator (bin/rails generate job SyncOpenOrders)
- [X] T009 [US1] Implement SyncOpenOrdersJob#perform method: connect to SQL Server via SqlServerConnector, fetch all records from vwZSDOrder_Advanced, call OpenOrdersImporter.import with fetched records
- [X] T010 [US1] Add error handling in SyncOpenOrdersJob: catch connection errors, query errors, import errors, log all errors with context, ensure old data preserved on failure
- [X] T011 [US1] Add structured logging in SyncOpenOrdersJob: log sync start with timestamp, log record count fetched, log batch progress (every 500 records), log sync completion with duration
- [X] T012 [US1] Create manual sync rake task in lib/tasks/sync.rake (task sync:open_orders) that calls SyncOpenOrdersJob.perform_now for testing
- [X] T013 [US1] Test manual sync via bin/rails sync:open_orders, verify records imported correctly, verify transaction rollback on error (simulate by disconnecting SQL Server)
- [ ] T014 [US1] Verify column mapping accuracy: spot-check 10 records comparing SQL Server data to Rails data for all 67 fields

**Checkpoint**: At this point, User Story 1 should be fully functional - manual sync works, data imports correctly with explicit mapping, errors are handled gracefully

---

## Phase 4: User Story 2 - Scheduled Recurring Sync (Priority: P1)

**Goal**: Sync job runs automatically every 5 minutes without manual intervention, providing near real-time data updates from SAP

**Independent Test**: Verify job runs automatically every 5 minutes, check logs confirm multiple successful executions, observe data refreshes consistently

### Implementation for User Story 2

- [X] T015 [US2] Configure recurring job in config/recurring.yml: add sync_open_orders entry with class SyncOpenOrdersJob, schedule "*/5 * * * *" (every 5 minutes), queue default
- [ ] T016 [US2] Restart application to load recurring job configuration (docker-compose restart web or kamal app restart)
- [ ] T017 [US2] Monitor logs for automatic execution: verify job runs at 5-minute intervals, verify no concurrent executions (Solid Queue handles this automatically), verify successful completions logged
- [ ] T018 [US2] Test application restart recovery: restart app during 5-minute window, verify schedule resumes correctly, verify no jobs lost

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - automatic scheduling runs correctly, manual trigger still works

---

## Phase 5: User Story 3 - Error Handling and Logging (Priority: P1)

**Goal**: When sync job encounters errors (connection failures, authentication issues, query errors), it logs detailed error information and does not corrupt or partially update the local database

**Independent Test**: Simulate connection failure by providing wrong credentials/host, verify job logs error clearly, confirm open_orders table remains unchanged (not truncated if fetch fails)

### Implementation for User Story 3

- [X] T019 [US3] Add connection error handling in SqlServerConnector: catch TinyTds::Error, log error with masked password (never log credentials), raise custom ConnectionError with details
- [X] T020 [US3] Add query error handling in SqlServerConnector: catch SQL execution errors, log query error with sanitized SQL (no credentials), raise custom QueryError
- [X] T021 [US3] Add import error handling in OpenOrdersImporter: wrap transaction in rescue block, catch ActiveRecord errors, rollback transaction on error, log import failure with record count context
- [X] T022 [US3] Update SyncOpenOrdersJob error handling: catch all custom errors, log at ERROR level with full exception details, do NOT update last sync timestamp on failure, allow Solid Queue to retry job
- [ ] T023 [US3] Test connection failure scenario: change database.yml host to invalid value, run sync, verify error logged correctly, verify open_orders unchanged, verify last sync timestamp NOT updated
- [ ] T024 [US3] Test authentication failure scenario: change database.yml password to wrong value, run sync, verify auth error logged with masked password, verify data unchanged
- [ ] T025 [US3] Test query failure scenario: change SQL query to invalid syntax in SqlServerConnector, run sync, verify query error logged, verify data unchanged
- [ ] T026 [US3] Test import failure scenario: introduce data type mismatch in OpenOrdersImporter, run sync, verify transaction rollback works, verify old data preserved

**Checkpoint**: All P1 user stories complete and independently functional - automatic sync works, errors handled gracefully, no data corruption possible

---

## Phase 6: User Story 4 - Sync Status Visibility (Priority: P2)

**Goal**: Administrators can view sync job status including last successful sync time, last error, and current sync progress through logs or web interface

**Independent Test**: Run a sync job, check logs show start/progress/completion messages, verify OpenOrders index page displays last sync timestamp

### Implementation for User Story 4

- [X] T027 [US4] Add last sync timestamp display to app/views/open_orders/index.html.erb: show "Last synced: [timestamp]" using OpenOrder.maximum(:updated_at) formatted with time_ago_in_words helper
- [X] T028 [US4] Update OpenOrdersHelper in app/helpers/open_orders_helper.rb: add format_last_sync_time helper method that returns formatted timestamp or "Never synced" if no records exist
- [X] T029 [US4] Add sync status indicator to index view: show green "✓ Synced" if last sync < 10 minutes ago, yellow "⚠ Stale" if 10-30 minutes ago, red "✗ Error" if > 30 minutes ago
- [ ] T030 [US4] Test status visibility: run manual sync, refresh index page, verify timestamp displays correctly, wait 5 minutes for automatic sync, verify timestamp updates

**Checkpoint**: All user stories complete - P1 core functionality working, P2 monitoring/visibility working

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T031 [P] Update README.md with SQL Server sync feature documentation: purpose, configuration, manual testing, troubleshooting
- [X] T032 [P] Add comments to COLUMN_MAPPING in app/services/open_orders_importer.rb documenting expected SQL Server column names and data types
- [X] T033 [P] Review and clean up logging: ensure consistent log format, appropriate log levels (INFO for success, WARN for recoverable, ERROR for failures), no credential leakage
- [X] T034 [P] Security review: verify credentials masked in all logs, verify database.yml not committed with real credentials (use ENV fallback for production), verify SQL injection prevention (parameterized queries only)
- [ ] T035 Rebuild Docker image with updated Dockerfile (FreeTDS dependencies): docker-compose build web
- [ ] T036 Test full deployment workflow: kamal setup (if first deploy) or kamal deploy, verify job runs in production environment, verify logs accessible via kamal app logs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 (Phase 3) completion - needs working sync job before scheduling
- **User Story 3 (Phase 5)**: Depends on User Story 1 (Phase 3) completion - enhances existing sync with error handling
- **User Story 4 (Phase 6)**: Independent of User Story 2/3 - only depends on User Story 1 (needs basic sync working)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Depends on User Story 1 - Must have working sync job before scheduling it
- **User Story 3 (P1)**: Can start after User Story 1 - Adds error handling to existing sync
- **User Story 4 (P2)**: Can start after User Story 1 - Independent of US2/US3, just displays sync status

### Within Each User Story

- **User Story 1**: T008 (generate job) → T009 (implement job logic) → T010 (error handling) → T011 (logging) → T012 (rake task) → T013/T014 (testing)
- **User Story 2**: T015 (configure recurring.yml) → T016 (restart app) → T017 (monitor) → T018 (test recovery)
- **User Story 3**: T019 (connection errors) → T020 (query errors) → T021 (import errors) → T022 (job-level handling) → T023-T026 (test scenarios)
- **User Story 4**: T027 (add timestamp display) → T028 (helper method) → T029 (status indicator) → T030 (test)

### Parallel Opportunities

- **Phase 1**: T001, T002 can run in parallel (different files)
- **Phase 2**: T005 and T006 can run in parallel (different service files)
- **Phase 7**: T031, T032, T033, T034 can run in parallel (different concerns)

---

## Parallel Example: Foundational Phase

```bash
# Developer A: SQL Server connector
Task T005: Create SqlServerConnector service in app/services/sql_server_connector.rb

# Developer B: Data importer (works on different file)
Task T006: Create OpenOrdersImporter service in app/services/open_orders_importer.rb

# Both can work simultaneously - no file conflicts
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003) → Gems and dependencies ready
2. Complete Phase 2: Foundational (T004-T007) → Services ready, connection tested
3. Complete Phase 3: User Story 1 (T008-T014) → Manual sync working
4. **STOP and VALIDATE**: Test manual sync thoroughly, verify data accuracy, verify error handling
5. Decision point: Deploy with manual sync only, or continue to automatic scheduling

### Incremental Delivery

1. **MVP v1**: Setup + Foundational + US1 → Manual sync working
2. **MVP v2**: Add US2 → Automatic 5-minute scheduling
3. **MVP v3**: Add US3 → Enhanced error handling and logging
4. **MVP v4**: Add US4 → Status visibility in UI
5. Each increment adds value without breaking previous functionality

### Parallel Team Strategy

With multiple developers after Foundational phase completes:

1. Team completes Setup + Foundational together (blocking)
2. Once Foundational done:
   - Developer A: User Story 1 (manual sync)
   - Developer B: Can prepare UI changes for User Story 4 (display logic only, waits for US1 data)
3. After US1 complete:
   - Developer A: User Story 2 (scheduling)
   - Developer B: User Story 3 (enhanced error handling)
   - Developer C: User Story 4 (complete status visibility)

---

## Implementation Notes

### Critical Path (Must Complete for Feature to Work)

1. ✅ Setup (Phase 1): Gems installed, Docker updated
2. ✅ Foundational (Phase 2): Services created, SQL Server connection working
3. ✅ User Story 1 (Phase 3): Manual sync working with correct data import
4. ✅ User Story 2 (Phase 4): Automatic scheduling enabled
5. ⚠️ User Story 3 (Phase 5): Error handling (CRITICAL for production reliability)

**Minimum Viable Feature**: Phases 1-4 complete (automatic sync working)  
**Production Ready**: Add Phase 5 (error handling) before production deployment  
**Full Feature**: All phases including Phase 6 (status visibility) and Phase 7 (polish)

### Testing Strategy (Manual - No Test Suite)

Each user story has specific test scenarios:

- **US1**: Manual sync via rake task, spot-check 10 records, verify counts match
- **US2**: Monitor logs for 15 minutes (3 automatic executions), verify schedule accuracy
- **US3**: Intentionally break connection/query/import, verify graceful handling, verify data preserved
- **US4**: Visual inspection of index page, verify timestamp updates after sync

### Risk Mitigation

- **Column Mapping Errors**: T014 explicitly validates 10 sample records against SQL Server source
- **Connection Failures**: T007 tests connection before implementing full sync logic
- **Transaction Rollback**: T026 explicitly tests rollback scenario with simulated error
- **Concurrent Execution**: Solid Queue prevents this automatically (no additional task needed)
- **Credentials Exposure**: T034 security review validates no credential leakage in logs

### Performance Validation

Expected metrics (for <5,000 records):
- Connection time: <5 seconds
- Fetch time: <30 seconds
- Import time: <60 seconds (500 records/batch)
- Total sync time: <2 minutes (well under 5-minute limit)

If sync takes >3 minutes, investigate:
- Network latency to SQL Server
- Batch size (reduce from 500 to 250)
- Database transaction overhead
- SQL query performance (missing indexes on SQL Server view)

---

## Task Checklist Summary

- **Phase 1 (Setup)**: 3 tasks
- **Phase 2 (Foundational)**: 4 tasks ⚠️ BLOCKING
- **Phase 3 (User Story 1 - P1)**: 7 tasks 🎯 MVP
- **Phase 4 (User Story 2 - P1)**: 4 tasks
- **Phase 5 (User Story 3 - P1)**: 8 tasks
- **Phase 6 (User Story 4 - P2)**: 4 tasks
- **Phase 7 (Polish)**: 6 tasks

**Total**: 36 tasks

**Estimated Effort**:
- Phase 1-2 (Setup + Foundational): 4-6 hours
- Phase 3 (US1): 6-8 hours (includes testing and validation)
- Phase 4 (US2): 2-3 hours
- Phase 5 (US3): 4-6 hours (extensive error scenario testing)
- Phase 6 (US4): 2-3 hours
- Phase 7 (Polish): 3-4 hours

**Total Estimated Effort**: 21-30 hours (3-4 days for single developer)

---

## Completion Criteria

Feature is complete when:

- [ ] All P1 user stories (US1, US2, US3) are implemented and tested
- [ ] Manual sync works correctly (T013 passes)
- [ ] Automatic sync runs every 5 minutes (T017 passes)
- [ ] All error scenarios tested and handled gracefully (T023-T026 pass)
- [ ] Column mapping validated for all 67 fields (T014 passes)
- [ ] No credentials exposed in logs (T034 security review passes)
- [ ] Deployed to production environment (T036 passes)
- [ ] README.md updated with feature documentation (T031)

**Optional for MVP** (can defer to later):
- [ ] User Story 4 (status visibility) - P2 priority
- [ ] All polish tasks (Phase 7) - nice to have

---

**Status**: Phase 2 tasks.md generation complete ✅ - Ready for implementation.
