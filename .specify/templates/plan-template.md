# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. For Rails 8 projects, many defaults are already defined in the
  constitution - only specify if deviating from those defaults.
-->

**Language/Version**: Ruby 3.2+ / Rails 8.0+ (per constitution)  
**Primary Dependencies**: [e.g., specific gems beyond Rails defaults, or NEEDS CLARIFICATION]  
**Storage**: SQLite3 (app data), SQL Server (external source) - per constitution, or [specify if different]  
**Testing**: None (per constitution - manual validation only)  
**Target Platform**: Linux server (Docker via Kamal) - per constitution  
**Project Type**: Rails worker application (background job processing)  
**Performance Goals**: [e.g., process 1,500-3,000 records per job run in <5 minutes, or NEEDS CLARIFICATION]  
**Constraints**: [e.g., must complete within maintenance window, API rate limits, or NEEDS CLARIFICATION]  
**Scale/Scope**: [e.g., number of jobs, frequency, data volume, or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **Rails Conventions First**: Does the design follow Rails 8 conventions? (generators, naming, REST, Hotwire)
- [ ] **Background Job Architecture**: Are long-running operations implemented as jobs? Are jobs idempotent?
- [ ] **Simplicity Over Optimization**: Is the solution simple? No premature optimization? Uses Rails conventions over abstractions?
- [ ] **Admin-Only Operations**: Does the feature avoid end-user UI? System-to-system or admin-only?
- [ ] **Modern Rails Stack**: Does it use Solid Queue/Cache/Cable, Propshaft, Tailwind, Kamal as appropriate?

*Any violations must be documented in Complexity Tracking section below with justification.*

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. For Rails applications, use standard Rails structure.
  Delete unused options and expand with real paths (e.g., app/models/order.rb).
-->

```text
# Rails 8 Application Structure (DEFAULT for this project)
app/
├── models/              # ActiveRecord models
├── jobs/                # Background jobs (Solid Queue)
├── services/            # Business logic services
├── controllers/         # Controllers (if API endpoints needed)
├── views/               # Views (minimal - admin only)
├── helpers/             # View helpers
└── mailers/             # Mailers (if needed)

config/
├── database.yml         # Database connections (SQLite + SQL Server)
├── recurring.yml        # Solid Queue recurring job schedule
└── routes.rb            # Routes (API endpoints if needed)

db/
├── migrate/             # Database migrations
├── schema.rb            # Schema definition
└── seeds.rb             # Seed data

lib/
└── tasks/               # Custom Rake tasks

# No test/ directory (per constitution - manual validation only)
```

**Structure Decision**: Standard Rails 8 structure with focus on app/jobs/ for
background processing. Models represent both local staging data and external
SQL Server data. Services encapsulate business logic for data transformation
and API communication.
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
