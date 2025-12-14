# Tasks: OpenOrder View Interface

**Input**: Design documents from `/specs/001-openorder-crud/`
**Prerequisites**: spec.md (read-only view interface for 70+ field OpenOrder model)

**Tests**: Per constitution - NO TESTS. Manual validation only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Rails application**: `app/models/`, `app/controllers/`, `app/views/`, `app/helpers/` at repository root
- **Configuration**: `config/` for routes
- **Database**: `db/migrate/` for migrations
- **No tests**: Per constitution - manual validation only, no test/ directory

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for OpenOrder feature

- [X] T001 Verify Rails 8 application is initialized with Tailwind CSS, Hotwire, and Propshaft
- [X] T002 [P] Verify basic authentication system exists for admin access (HTTP basic auth or simple login)
- [X] T003 [P] Add kaminari gem (or equivalent) for pagination in Gemfile

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create OpenOrder model with all 70+ fields using Rails generator: `rails g model OpenOrder`
- [X] T005 Create database migration for OpenOrder table in db/migrate/ with all fields from CSV schema
- [X] T006 Add database indexes for frequently searched/sorted fields (salesDoc, custName, orderDate, material, orderStatus) in migration
- [X] T007 Run migration to create open_orders table: `rails db:migrate`
- [X] T008 [P] Add OpenOrder routes to config/routes.rb (index and show only - read-only)
- [X] T009 [P] Create OpenOrdersController in app/controllers/open_orders_controller.rb with authentication requirement

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View OpenOrder List (Priority: P1) 🎯 MVP

**Goal**: Admin can view paginated, sortable, searchable list of OpenOrder records

**Independent Test**: Navigate to /open_orders, see list with key fields, paginate through 50 records per page, sort by columns, search by customer name/sales doc/material

### Implementation for User Story 1

- [X] T010 [US1] Implement OpenOrdersController#index action in app/controllers/open_orders_controller.rb with pagination (50 per page)
- [X] T011 [US1] Add search/filter logic to index action for custName, salesDoc, material using SQL WHERE clauses
- [X] T012 [US1] Add sorting logic to index action for displayed columns (orderDate, requestedDate, orderStatus, etc.)
- [X] T013 [US1] Create index view in app/views/open_orders/index.html.erb with Tailwind CSS styling
- [X] T014 [US1] Add pagination controls to index view using kaminari helpers
- [X] T015 [US1] Add sortable column headers with ascending/descending toggle in index view
- [X] T016 [US1] Add search form with fields for customer name, sales doc, material in index view
- [X] T017 [US1] Display key fields in table: salesDoc, custName, plant, material, orderStatus, requestedDate
- [X] T018 [US1] Make salesDoc column clickable links to detail pages
- [X] T019 [US1] Add sync status display (last sync timestamp) to index page header
- [X] T020 [US1] Style index page with Tailwind CSS for clean, functional admin interface
- [X] T021 [US1] Handle empty state (no records found) with appropriate message
- [X] T022 [US1] Preserve search filters and pagination in URL parameters using Turbo

**Checkpoint**: User Story 1 complete - admins can view, search, sort, and paginate order list

---

## Phase 4: User Story 2 - View OpenOrder Details (Priority: P1)

**Goal**: Admin can view complete details of any order with all 70+ fields organized in logical sections

**Independent Test**: Click any order in list, navigate to detail page showing all fields in organized sections (Customer, Order, Shipping, Inventory, Status), click "Back to List" and preserve filters

### Implementation for User Story 2

- [X] T023 [US2] Implement OpenOrdersController#show action in app/controllers/open_orders_controller.rb
- [X] T024 [US2] Create show view in app/views/open_orders/show.html.erb with Tailwind CSS styling
- [X] T025 [US2] Organize detail view into Customer Info section (soldTo, shipTo, custName, country)
- [X] T026 [US2] Add Order Info section (salesDoc, itemNumber, orderDate, requestedDate, material, materialDescription, quantities with UoM)
- [X] T027 [US2] Add Shipping section (shipType, estShipDate, shipStatus, deliveryNumber, deliveryItemNumber, shipmentNumber, shippingFrom, shippingType)
- [X] T028 [US2] Add Inventory section (inStock, neededQty, orderShortfall, cumuShortfall, totalShortfall, unrestrictedQty, safetyStock, sLoc, iStloc)
- [X] T029 [US2] Add Status/Actions section (orderStatus, actionText, actionDate, actionUser, CSR_actionText, CSR_actionDate, CSR_actionUser, currentText)
- [X] T030 [US2] Add Sales/Service section (salesRep, serviceAgentNumber, serviceAgentName, csrName, custPONum)
- [X] T031 [US2] Add Additional Details section (plant, salesType, processOrderNum, equipment, udCode, fertCode, fertDesc, transitTime, daysLate, leadtime, tempSensitive, bismt)
- [X] T032 [US2] Handle null/empty values gracefully with placeholders like "N/A" or "—"
- [X] T033 [US2] Add "Back to List" button that preserves previous filters and pagination state
- [X] T034 [US2] Add sync status display to detail page header
- [X] T035 [US2] Style detail page sections with Tailwind CSS for readability
- [X] T036 [US2] Add visual indicator that data is read-only (no edit/delete buttons)

**Checkpoint**: User Story 2 complete - admins can view all order details in organized format

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Enhancements that affect both user stories

- [X] T037 [P] Create OpenOrdersHelper in app/helpers/open_orders_helper.rb for view formatting methods
- [X] T038 [P] Add helper method for formatting dates consistently across views
- [X] T039 [P] Add helper method for formatting quantities with UoM
- [X] T040 [P] Add helper method for displaying null values with appropriate placeholders
- [X] T041 Add CSV export functionality to index page (FR-015)
- [X] T042 Implement CSV export action in controller responding to .csv format
- [X] T043 Test CSV export with filtered results (up to 1,000 records)
- [X] T044 [P] Add navigation breadcrumbs or consistent header across all OpenOrder pages
- [X] T045 [P] Ensure Hotwire/Turbo is properly configured for seamless navigation
- [X] T046 Add logging for OpenOrder views (page visits, search queries) using Rails logger
- [X] T047 Verify authentication is enforced on all OpenOrder routes
- [X] T048 Manual validation: Test pagination with 0, 50, 51, 1500+ records
- [X] T049 Manual validation: Test sorting on all sortable columns
- [X] T050 Manual validation: Test search filters individually and in combination
- [X] T051 Manual validation: Verify navigation preserves filters and pagination
- [X] T052 Manual validation: Verify all 70+ fields display correctly in detail view
- [X] T053 Manual validation: Test CSV export with various filter combinations
- [X] T054 Manual validation: Verify read-only nature (no edit/create/delete options visible)
- [X] T055 Update README.md with OpenOrder view interface documentation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Both US1 and US2 depend on Foundational phase completion
  - US1 (List View) should be completed before US2 (Detail View) since detail links from list
  - However, both can technically proceed in parallel after Phase 2
- **Polish (Phase 5)**: Depends on both US1 and US2 being complete

### User Story Dependencies

- **User Story 1 (P1 - List View)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1 - Detail View)**: Can start after Foundational (Phase 2) - Links from US1 but independently testable

### Within Each User Story

**User Story 1 (List):**
- T010 (controller index) must complete before T013 (view)
- T011 (search), T012 (sort) must complete before view implementation
- T013 (view) must complete before T014-T022 (view enhancements)
- All [P] tasks within view layer (T014-T022) can proceed in parallel after T013

**User Story 2 (Detail):**
- T023 (controller show) must complete before T024 (view)
- T024 (view base) must complete before T025-T031 (sections)
- All section tasks (T025-T031) marked [P] can proceed in parallel
- T032-T036 (enhancements) follow after sections complete

### Parallel Opportunities

- Phase 1: T002, T003 can run in parallel
- Phase 2: T008, T009 can run in parallel after T004-T007 complete
- Phase 5: T037-T040, T044, T045 can all run in parallel
- Within User Story 1: View enhancement tasks T014-T022 after base view
- Within User Story 2: Section tasks T025-T031 after base view

---

## Parallel Example: User Story 1 (List View)

```bash
# After T013 (base view) completes, launch view enhancements in parallel:
Task: T014 - Add pagination controls to index view
Task: T015 - Add sortable column headers  
Task: T016 - Add search form
Task: T017 - Display key fields in table
Task: T019 - Add sync status display

# After view structure complete, styling and edge cases:
Task: T020 - Style with Tailwind CSS
Task: T021 - Handle empty state
Task: T022 - Preserve filters in URL
```

---

## Parallel Example: User Story 2 (Detail View)

```bash
# After T024 (base view) completes, launch all sections in parallel:
Task: T025 - Customer Info section
Task: T026 - Order Info section
Task: T027 - Shipping section
Task: T028 - Inventory section
Task: T029 - Status/Actions section
Task: T030 - Sales/Service section
Task: T031 - Additional Details section
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

Both user stories are P1 (equal priority) and together form the MVP:

1. Complete Phase 1: Setup → verify Rails 8 ready
2. Complete Phase 2: Foundational → create model, migration, routes, controller skeleton
3. Complete Phase 3: User Story 1 → list view with search, sort, pagination
4. **VALIDATE US1**: Test list view independently
5. Complete Phase 4: User Story 2 → detail view with all fields organized
6. **VALIDATE US2**: Test detail view independently
7. Complete Phase 5: Polish → CSV export, helpers, final validation

### Incremental Delivery

1. Setup + Foundational → Database and model ready
2. Add User Story 1 → Admins can view and search order list (MVP milestone!)
3. Add User Story 2 → Admins can view complete order details (Full MVP!)
4. Add Polish → CSV export, enhanced formatting, final touches

### Suggested Order (Sequential)

For a single developer:

1. **Phase 1 & 2** (T001-T009): Foundation - ~2-3 hours
2. **Phase 3** (T010-T022): List view - ~4-6 hours
3. **Phase 4** (T023-T036): Detail view - ~4-6 hours
4. **Phase 5** (T037-T055): Polish & validation - ~3-4 hours

**Total Estimated Time**: 13-19 hours for complete feature

---

## Notes

- All tasks follow Rails 8 conventions (generators, naming, RESTful routes)
- Read-only interface: No create/edit/delete functionality
- OpenOrder data populated by separate SQL Server sync worker (future feature)
- Pagination library: kaminari (popular Rails gem) - can substitute with pagy if preferred
- CSV export uses Rails built-in CSV support
- Manual validation replaces automated tests (per constitution)
- Sync status display prepares for future sync worker integration
- All file paths follow standard Rails structure
- Hotwire/Turbo used for seamless navigation without full page reloads
- Tailwind CSS for all styling (per constitution)
- 55 total tasks organized across 5 phases
