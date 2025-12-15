# Platform01 Inside Worker

A Rails 8 background worker application that syncs OpenOrder data from SAP SQL Server and provides a minimal admin interface for viewing order information.

## Overview

Platform01 Inside Worker is designed to:
- **Fetch OpenOrder data from SQL Server** - Recurring background job syncs data from SAP every 5 minutes
- **Send data to another Rails application via API calls** (future feature)
- Provide read-only admin interface for viewing OpenOrder data

This application follows the **Platform01 Inside Worker Constitution v1.0.1** which emphasizes Rails conventions, background job architecture, simplicity, and admin-only operations.

## Ruby Version

- Ruby 3.3.5
- Rails 8.1.1

## System Dependencies

- **SQLite3** - Local data storage for synced OpenOrder data
- **SQL Server** - External SAP data source (CASQL2.inxintl.com)
- **FreeTDS** - SQL Server connectivity library for TinyTDS
- **TinyTDS gem** (~> 2.1) - Ruby SQL Server adapter
- Modern browser with JavaScript enabled

## Configuration

### Environment Variables

Required for admin authentication:

```bash
ADMIN_USERNAME=your_admin_username
ADMIN_PASSWORD=your_secure_password
```

Optional:
- `DATABASE_URL` - Database connection string (defaults to SQLite3)
- `RAILS_ENV` - Environment (development/production/test)
- `SQL_SERVER_PASSWORD` - SQL Server password (defaults to value in database.yml)

### SQL Server Configuration

The application connects to SAP SQL Server to fetch OpenOrder data. Configuration is in `config/database.yml`:

```yaml
sqlserver:
  adapter: sqlserver
  mode: dblib
  host: CASQL2.inxintl.com
  database: ProcessStatus
  username: zsdOrder8800
  password: <%= ENV.fetch('SQL_SERVER_PASSWORD', '3~EmX~Kf$}') %>
  timeout: 30
  encoding: utf8
```

**Note**: Password is stored in config file for firewalled network deployment. For external deployment, use environment variable only.

### Database Setup

```bash
# Create database and run migrations
bin/rails db:create
bin/rails db:migrate

# Optional: Load seed data for testing
bin/rails db:seed
```

## Features

### SQL Server Data Sync (New!)

Automatic background job that syncs OpenOrder data from SAP SQL Server:

- **Recurring Schedule**: Runs every 5 minutes automatically
- **Batch Processing**: Processes records in batches of 500 for memory efficiency
- **Transaction Safety**: Truncates and replaces all data atomically - old data preserved on failure
- **Explicit Column Mapping**: 67 fields mapped explicitly from SQL Server to Rails (fail-fast approach)
- **Error Handling**: Comprehensive logging, connection errors don't corrupt data
- **Status Visibility**: Web interface shows last sync time with color-coded status:
  - 🟢 **Synced** (< 10 minutes ago)
  - 🟡 **Stale** (10-30 minutes ago)
  - 🔴 **Error** (> 30 minutes ago)

#### Manual Sync

Trigger sync manually for testing:

```bash
bin/rails sync:open_orders
```

#### Monitoring

Check sync status:
- Web interface: `/open_orders` shows last sync time and status
- Logs: `log/development.log` or `log/production.log`
- Solid Queue dashboard: Check recurring job execution history

#### Troubleshooting

See `specs/002-sqlserver-sync-worker/quickstart.md` for:
- Connection testing scripts
- Common error scenarios
- Performance tuning
- Emergency procedures

### OpenOrder View Interface

The application provides a read-only web interface for viewing OpenOrder data synced from SAP:

#### List View (`/open_orders`)
- **Pagination**: 50 records per page with Kaminari
- **Search**: Filter by customer name, sales document, or material
- **Sorting**: Click column headers to sort by:
  - Order Date
  - Requested Date  
  - Customer Name
  - Plant
  - Material
  - Order Status
- **CSV Export**: Export up to 1,000 records with current filters
- **Sync Status**: Displays last data sync timestamp

#### Detail View (`/open_orders/:id`)
Comprehensive view of all 70+ fields organized into 7 sections:
1. **Customer Information**: Customer name, sold-to, ship-to, country, PO details
2. **Order Information**: Sales doc, material, dates, quantities, UOM
3. **Shipping & Delivery**: Shipping point, delivery dates, tracking, goods issue
4. **Inventory & Availability**: Stock levels, ATP, allocations, transit data
5. **Status & Actions**: Order status, blocks, CSR actions, change history
6. **Sales & Service**: Sales org, distribution channel, CSR promises/reconfirms
7. **Additional Details**: Item category, pricing, batch/serial numbers, texts

#### Security
- HTTP Basic Authentication protects all OpenOrder routes
- Credentials configured via environment variables
- Read-only interface - no create/edit/delete operations

## Running the Application

### Development

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start development server with Tailwind CSS compilation
bin/dev
```

Access the application at `http://localhost:3000`

Default credentials (if not configured):
- Username: `admin`
- Password: `password`

### Production

Deploy using Kamal (configured in `config/deploy.yml`):

```bash
# Setup servers
kamal setup

# Deploy application
kamal deploy
```

## Application Architecture

### Modern Rails Stack
- **Asset Pipeline**: Propshaft
- **CSS Framework**: Tailwind CSS (tailwindcss-rails gem v4.4.0)
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Background Jobs**: Solid Queue (recurring sync job every 5 minutes)
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Pagination**: Kaminari v1.2.2
- **SQL Server**: TinyTDS v2.1 with FreeTDS

### Database Schema

**OpenOrders Table** (70+ fields):
- Customer fields: `sold_to`, `ship_to`, `cust_name`, `country`, `cust_po`
- Order fields: `sales_doc`, `item_number`, `material`, `order_date`, `requested_date`
- Quantity fields: `order_qty`, `confirm_qty`, `pick_qty`, `shipped_qty`
- Inventory fields: `unrestricted_stock`, `allocated_stock`, `available_stock`
- Status fields: `order_status`, `delivery_status`, `rejection_status`, `blocked_status`
- CSR fields: `csr_promised_date`, `csr_promised_quantity`, `csr_rejection_reason`
- And 40+ more fields for comprehensive order tracking

**Indexes**:
- `sales_doc` (primary lookup)
- `cust_name` (search performance)
- `order_date` (default sorting)
- `material` (product filtering)
- `order_status` (status filtering)

## Testing

No formal test suite per constitution principle:
> "No tests, just ship. If it breaks, we fix it. Keep the dev loop fast."

Manual validation performed for:
- Pagination with various record counts
- Sorting on all columns
- Search functionality
- Navigation and filter preservation
- CSV export with filters
- All 70+ fields in detail view

## Deployment

Uses Kamal for containerized deployment. See `config/deploy.yml` for configuration.

```bash
# First time setup
kamal setup

# Deploy updates
kamal deploy

# View logs
kamal app logs

# Access console
kamal app exec -i --reuse "bin/rails console"
```

## Future Features

As specified in the constitution, future development includes:
1. ~~**SQL Server Sync Worker**: Recurring job to fetch data from SAP SQL Server~~ ✅ **Completed**
2. **API Integration**: Send synced data to external Rails application
3. **Data Transformations**: Process and normalize SAP data as needed

## Project Structure

```
app/
├── controllers/
│   └── open_orders_controller.rb    # List, detail, CSV export
├── models/
│   └── open_order.rb                 # ActiveRecord model
├── jobs/
│   └── sync_open_orders_job.rb       # SQL Server sync recurring job
├── services/
│   ├── sql_server_connector.rb       # TinyTDS connection management
│   └── open_orders_importer.rb       # Batch import with column mapping
├── views/
│   ├── layouts/
│   │   └── application.html.erb      # Main layout with Tailwind
│   ├── open_orders/
│   │   ├── index.html.erb            # List view with sync status
│   │   └── show.html.erb             # Detail view
│   ├── shared/
│   │   └── _sync_status.html.erb     # Sync status indicator partial
│   └── kaminari/                     # Pagination templates
├── helpers/
│   └── open_orders_helper.rb         # Date/quantity/sync formatters
config/
├── routes.rb                         # RESTful routes (index, show)
├── database.yml                      # SQLite3 + SQL Server configs
├── recurring.yml                     # Solid Queue job schedule
└── deploy.yml                        # Kamal deployment config
db/
└── migrate/
    └── *_create_open_orders.rb       # Table schema
lib/
└── tasks/
    └── sync.rake                     # Manual sync task
specs/
├── 001-openorder-crud/              # OpenOrder CRUD feature docs
└── 002-sqlserver-sync-worker/       # SQL Server sync feature docs
    ├── spec.md                       # Feature specification
    ├── plan.md                       # Implementation plan
    ├── research.md                   # Technical research
    ├── data-model.md                 # Column mapping documentation
    ├── quickstart.md                 # Setup and troubleshooting guide
    └── tasks.md                      # Implementation tasks
```

## Contributing

This project follows the **Platform01 Inside Worker Constitution**. Key principles:

1. **Rails Conventions First**: Use Rails defaults and conventions
2. **Background Job Architecture**: Use Solid Queue for async processing
3. **Simplicity Over Optimization**: Solve real problems, not imagined ones
4. **Admin-Only Operations**: Minimal UI for monitoring and viewing
5. **Modern Rails Stack**: Rails 8, Hotwire, Tailwind, SQLite3, Solid gems

## License

[Your license here]

## Documentation

- Constitution: `.specify/memory/constitution.md`
- **Feature 001** - OpenOrder CRUD: `specs/001-openorder-crud/`
  - Specification: `spec.md`
  - Implementation Tasks: `tasks.md`
- **Feature 002** - SQL Server Sync Worker: `specs/002-sqlserver-sync-worker/`
  - Specification: `spec.md`
  - Implementation Plan: `plan.md`
  - Technical Research: `research.md`
  - Column Mapping: `data-model.md`
  - Setup & Troubleshooting: `quickstart.md`
  - Implementation Tasks: `tasks.md`
