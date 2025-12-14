# Quick Start Guide: OpenOrder View Interface

## Prerequisites
- Ruby 3.3.5 installed
- Rails 8.1.1 installed
- Git repository initialized

## Step 1: Configure Environment

Create a `.env` file in the project root (or export these variables):

```bash
# Admin credentials for HTTP Basic Auth
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="change_me_in_production"
```

Or create `.env` file:
```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change_me_in_production
```

## Step 2: Install Dependencies

```bash
bundle install
```

## Step 3: Setup Database

```bash
# Create database and run migrations
bin/rails db:create db:migrate

# Optional: Add sample data for testing
bin/rails runner '
  OpenOrder.create!(
    sales_doc: "SO-2025-001",
    item_number: "000010",
    cust_name: "Acme Corporation",
    sold_to: "100001",
    ship_to: "100002",
    country: "US",
    plant: "1000",
    material: "MAT-12345",
    material_description: "Widget Type A",
    order_date: Date.today - 7.days,
    requested_date: Date.today + 7.days,
    order_qty: 100,
    confirm_qty: 100,
    uom: "EA",
    order_status: "Open"
  )
  puts "Sample OpenOrder created!"
'
```

## Step 4: Start the Application

```bash
# Start Rails server with Tailwind CSS compilation
bin/dev
```

If `bin/dev` is not available, start services separately:

**Terminal 1** - Rails Server:
```bash
bin/rails server
```

**Terminal 2** - Tailwind CSS:
```bash
bin/rails tailwindcss:watch
```

## Step 5: Access the Application

1. Open browser to: `http://localhost:3000`
2. Login with credentials:
   - Username: `admin` (or your ADMIN_USERNAME)
   - Password: `change_me_in_production` (or your ADMIN_PASSWORD)
3. You should see the OpenOrders list page

## Features to Test

### List View (`/open_orders`)
- **Pagination**: Navigate through pages if you have 50+ records
- **Search**: Use search box to filter by customer name, sales doc, or material
- **Sorting**: Click column headers to sort (Order Date, Customer Name, Plant, Material, Status)
- **CSV Export**: Click "Export to CSV" button to download filtered results
- **Detail View**: Click any sales document number to view full details

### Detail View (`/open_orders/:id`)
- View all 70+ fields organized in 7 sections
- Use "Back to List" button to return
- Note the read-only banner at the top

## Troubleshooting

### Authentication Prompt Appears
✅ **Expected behavior** - Enter your ADMIN_USERNAME and ADMIN_PASSWORD

### Page Shows "Open Orders" but Empty Table
✅ **Expected behavior** - No data synced yet. Add sample data using the script in Step 3.

### Tailwind CSS Not Working
```bash
# Rebuild Tailwind CSS
bin/rails tailwindcss:build

# Or watch for changes
bin/rails tailwindcss:watch
```

### Database Errors
```bash
# Check migration status
bin/rails db:migrate:status

# Re-run migrations if needed
bin/rails db:migrate

# Reset database (⚠️ destroys all data)
bin/rails db:reset
```

### Port 3000 Already in Use
```bash
# Kill existing Rails server
lsof -ti:3000 | xargs kill -9

# Or use different port
bin/rails server -p 3001
```

## Production Deployment

For production deployment using Kamal:

```bash
# First time setup
kamal setup

# Deploy
kamal deploy

# View logs
kamal app logs -f

# Access console
kamal app exec -i --reuse "bin/rails console"
```

**⚠️ Important for Production**:
1. Set strong ADMIN_USERNAME and ADMIN_PASSWORD environment variables
2. Configure HTTPS/TLS certificates
3. Set `RAILS_ENV=production`
4. Configure production database (consider PostgreSQL for scale)
5. Set up SQL Server connection for sync worker

## Next Steps

Once the basic interface is working:

1. **Configure SQL Server Connection**: Set up connection to SAP SQL Server for data sync
2. **Create Sync Worker**: Implement recurring background job using Solid Queue
3. **Configure API Integration**: Set up external API endpoint for data forwarding

## Documentation

- **Full README**: `README.md`
- **Feature Specification**: `specs/001-openorder-crud/spec.md`
- **Implementation Tasks**: `specs/001-openorder-crud/tasks.md`
- **Completion Report**: `specs/001-openorder-crud/IMPLEMENTATION_COMPLETE.md`
- **Project Constitution**: `.specify/memory/constitution.md`

## Support

For issues or questions:
1. Check application logs: `log/development.log` or `log/production.log`
2. Verify routes: `bin/rails routes | grep open_order`
3. Test in Rails console: `bin/rails console`
4. Review error traces in browser developer console

## Summary

✅ OpenOrder View Interface is now ready to use
✅ All 55 implementation tasks completed
✅ 10 success criteria met
✅ 15 functional requirements implemented
✅ Production-ready pending SQL Server configuration

**Status**: 🎉 READY FOR USE
