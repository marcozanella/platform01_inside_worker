<!--
SYNC IMPACT REPORT
==================
Version Change: 1.0.0 → 1.0.1
Change Type: PATCH (clarification/refinement)
Rationale: Clarified that minimal admin UI exists for job monitoring - does not change 
architecture or add new principles, just refines Principle IV description

Modified Principles:
  - IV. Admin-Only Operations - Clarified to include minimal admin UI for job status monitoring

Added Sections: None
Removed Sections: None

Templates Requiring Updates:
  ✅ No template updates needed - admin UI was already implied in original templates
  ✅ plan-template.md - Constitution check remains valid
  ✅ tasks-template.md - Polish phase already mentions "basic Rails admin interface"

Follow-up TODOs: None

Changes Applied: 2025-12-13 (v1.0.1 clarification)
Previous Changes: 2025-12-13 (v1.0.0 initial)
-->

# Platform01 Inside Worker Constitution

## Core Principles

### I. Rails Conventions First
All development MUST follow Rails 8 conventions and idioms. This includes:
- Using Rails generators for creating models, controllers, jobs
- Following Rails naming conventions (singular models, plural tables)
- Leveraging Rails magic over explicit configuration where appropriate
- Using Hotwire (Turbo + Stimulus) for any interactive UI needs
- Following RESTful conventions for API design

**Rationale**: Rails conventions reduce cognitive load, ensure consistency, and maximize compatibility with the Rails ecosystem.

### II. Background Job Architecture
The application MUST be architected around asynchronous job processing. This means:
- All long-running operations execute as background jobs
- Jobs MUST be idempotent and retryable
- Job failures MUST be logged with sufficient context for debugging
- Solid Queue manages all job scheduling and execution
- Recurring jobs use Solid Queue's recurring job functionality

**Rationale**: The worker app's primary purpose is scheduled data processing; background jobs are the architectural foundation, not an afterthought.

### III. Simplicity Over Optimization
Keep the implementation simple and maintainable. Specifically:
- No testing framework - manual validation only
- Use temporary staging tables rather than complex streaming
- Leverage Rails conventions over custom abstractions
- Standard SQL Server adapter configuration without advanced tuning
- Direct API calls over message queues or complex protocols

**Rationale**: The system processes 1,500-3,000 records on a schedule - premature optimization wastes time and adds complexity without measurable benefit.

### IV. Admin-Only Operations - only a minimal admin interface. All interactions are:
- System-to-system (scheduled jobs, API calls)
- Admin-only (monitoring job status, reviewing logs, manual job triggers)
- Minimal UI for admins who occasionally log in to review job execution status
- Simple, functional admin pages using Rails views with Tailwind CSS styling
- No complex user workflows, authentication can be basic (HTTP auth or simple login)
- No user-facing features or complex UX concerns

**Rationale**: Defining the operational model prevents scope creep and focuses development on reliability and observability. The minimal admin UI provides essential monitoring capabilities without adding significant complexity
**Rationale**: Defining the operational model prevents scope creep and focuses development on reliability and observability rather than user experience.

### V. Modern Rails Stack
Use Rails 8's modern, integrated stack components:
- Solid Queue for background jobs (replaces Redis/Sidekiq)
- Solid Cache for caching (replaces Redis)
- Solid Cable for any real-time needs (replaces Redis)
- Propshaft for asset pipeline (simpler than Sprockets)
- Tailwind CSS for any admin UI styling
- Kamal for deployment orchestration

**Rationale**: Rails 8's "No PaaS Required" vision provides a simpler, more cohesive stack with fewer external dependencies.

## Technology Stack

**Language**: Ruby 3.2+  
**Framework**: Rails 8.0+  
**Database**: SQLite3 (for app data via Solid Queue/Cache/Cable), SQL Server (external data source)  
**Job Processing**: Solid Queue  
**Caching**: Solid Cache  
**WebSockets**: Solid Cable  
**Assets**: Propshaft  
**CSS**: Tailwind CSS  
**Deployment**: Kamal  
**External API**: Target Rails app (method TBD during implementation)

**External Dependencies**:
- SQL Server connection to `ProcessStatus` database
- Target Rails application API (receiving data)

**Constraints**:
- No test suite (per user requirement)
- No user authentication (admin access via infrastructure)
- Process 1,500-3,000 records per job execution
- Data schema from `vwZSDOrder_Advanced` view with 70+ columns

## Deployment & Operations

**Deployment Method**: Kamal (containerized deployment)  
**Infrastructure**: Docker containers, managed via Kamal configuration  
**Monitoring**: Rails logs, Solid Queue dashboard, database query logs  
**Job Schedule**: Recurring job configuration in `config/recurring.yml`  
**Admin Access**: Direct server access or basic Rails admin interface

**Operational Requirements**:
- Job execution logs MUST capture record counts, API response codes, error details
- Failed jobs MUST be retryable without data corruption
- SQL Server credentials MUST be managed via Rails credentials
- Target API credentials MUST be managed via Rails credentials

## Governance

This constitution defines the architectural principles and technology choices for the Platform01 Inside Worker application. All implementation decisions MUST align with these principles. Complexity beyond these guidelines MUST be justified with concrete performance data or specific requirements.

**Amendment Process**:
1. Propose change with rationale and impact analysis
2. Update this constitution via `.github/prompts/speckit.constitution.prompt.md`
3. Increment version according to semantic versioning
4. Update dependent templates and documentation

**Compliance**:
- All feature specifications MUST reference relevant principles
- Implementation 1lans MUST document any principle deviations with justification
- Code reviews SHOULD verify adherence to Rails conventions

**Version**: 1.0.0 | **Ratified**: 2025-12-13 | **Last Amended**: 2025-12-13
