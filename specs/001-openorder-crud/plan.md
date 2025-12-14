# Implementation Plan: OpenOrder View Interface

**Branch**: `001-openorder-crud` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-openorder-crud/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a read-only admin interface for viewing OpenOrder records synced from SQL Server. The interface provides a paginated list view with search/filter/sort capabilities and a detail view showing all 70+ fields organized into logical sections. Uses Rails 8 conventions with Hotwire/Turbo for seamless navigation and Tailwind CSS for styling.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.1.1 (per constitution, confirmed in Gemfile)
**Primary Dependencies**: Rails defaults (Hotwire/Turbo, Stimulus) + Tailwind CSS for styling, Pagy gem for pagination
**Storage**: SQLite3 (app data via storage/*.sqlite3) - per constitution
**Testing**: None (per constitution - manual validation only)
**Target Platform**: Linux server (Docker via Kamal) - per constitution
**Project Type**: Rails admin interface (read-only views for background job data)
**Performance Goals**: List page loads 50 records in <3 seconds, search returns in <2 seconds, detail page loads in <1 second
**Constraints**: Read-only interface (no CUD operations), admin-only access, data populated by future sync worker
**Scale/Scope**: Up to 5,000 OpenOrder records, 1-5 concurrent admin users, pagination at 50 records/page

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Rails Conventions First**: YES - Uses Rails generators, RESTful routes (/open_orders, /open_orders/:id), standard naming (OpenOrder model, OpenOrdersController), Hotwire/Turbo for page transitions
- [x] **Background Job Architecture**: N/A for this feature - This is a read-only view interface. Data population is handled by a separate sync worker feature (out of scope)
- [x] **Simplicity Over Optimization**: YES - Standard Rails scaffolding patterns, Pagy for pagination (lightweight), direct Active Record queries, no complex abstractions
- [x] **Admin-Only Operations**: YES - Minimal admin UI for viewing order data, basic authentication, no end-user features
- [x] **Modern Rails Stack**: YES - Propshaft (asset pipeline), Tailwind CSS (styling), Hotwire/Turbo (interactions), SQLite3 (storage)

**Initial Gate Status**: ✅ PASS - No violations. Design aligns with all constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/001-openorder-crud/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── open_orders_api.yml  # OpenAPI spec for read-only endpoints
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Files created/modified by this feature
app/
├── models/
│   └── open_order.rb           # OpenOrder model (70+ fields)
├── controllers/
│   └── open_orders_controller.rb  # Index, show actions only
├── views/
│   └── open_orders/
│       ├── index.html.erb      # Paginated list view
│       ├── show.html.erb       # Detail view (all fields)
│       └── _order_row.html.erb # Turbo Frame partial for list rows
└── helpers/
    └── open_orders_helper.rb   # Display formatting helpers

config/
├── routes.rb                   # Add resources :open_orders, only: [:index, :show]
└── initializers/
    └── pagy.rb                 # Pagination configuration

db/
├── migrate/
│   └── YYYYMMDDHHMMSS_create_open_orders.rb  # Migration with 70+ columns
└── seeds.rb                    # Sample data for development

# No test/ directory (per constitution - manual validation only)
```

**Structure Decision**: Standard Rails 8 MVC structure. Read-only controller with index/show only. Views use Turbo Frames for seamless pagination and navigation. Helper methods format field values for display.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
