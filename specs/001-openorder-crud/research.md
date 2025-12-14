# Research: OpenOrder View Interface

**Feature**: 001-openorder-crud
**Date**: 2025-12-14
**Status**: Complete

## Research Topics

### 1. Pagination Library Selection

**Decision**: Use Pagy gem for pagination

**Rationale**:
- Pagy is the fastest and most memory-efficient pagination gem for Ruby
- Native support for Turbo/Hotwire with `pagy_turbo` extras
- Simple configuration, minimal dependencies
- Preserves query params (search filters, sort) automatically
- Supports multiple collections on same page if needed

**Alternatives Considered**:
- **Kaminari**: Heavier, slower, more complex API - rejected for simplicity
- **will_paginate**: Legacy, less maintained, no Turbo support - rejected
- **Manual LIMIT/OFFSET**: No helpers for UI controls - rejected

**Implementation Notes**:
```ruby
# Gemfile
gem 'pagy', '~> 9.0'

# config/initializers/pagy.rb
Pagy::DEFAULT[:limit] = 50
Pagy::DEFAULT[:size] = 7  # pagination links

# Controller
include Pagy::Backend
@pagy, @open_orders = pagy(OpenOrder.all)

# View
include Pagy::Frontend
<%== pagy_nav(@pagy) %>
```

---

### 2. Admin Authentication Approach

**Decision**: Use Rails 8 built-in authentication generator

**Rationale**:
- Rails 8 includes `rails generate authentication` for simple session-based auth
- Creates User model, sessions controller, password resets out of the box
- No external gems required (Devise is overkill for 1-5 admin users)
- Follows Rails conventions, easy to maintain
- Can be extended later if needed

**Alternatives Considered**:
- **HTTP Basic Auth**: Too simple, no session management, poor UX - rejected
- **Devise**: Overkill for 1-5 users, adds complexity - rejected
- **Clearance**: Another gem dependency, Rails 8 has built-in - rejected
- **Custom from scratch**: Unnecessary when Rails 8 provides generator - rejected

**Implementation Notes**:
```bash
# Generate authentication scaffold
bin/rails generate authentication

# Creates:
# - app/models/user.rb
# - app/controllers/sessions_controller.rb
# - app/controllers/concerns/authentication.rb
# - db/migrate/xxx_create_users.rb
# - Views for login/logout
```

---

### 3. Table Styling for 70+ Fields

**Decision**: Horizontal scroll table for list view, grouped card sections for detail view

**Rationale**:
- List view shows only key fields (6-8 columns) with horizontal scrolling for more
- Detail view organizes 70+ fields into collapsible/grouped sections
- Tailwind CSS provides all needed utilities without additional CSS
- Desktop-only (per spec), so responsive tables not required

**Alternatives Considered**:
- **Vertical key-value list**: Poor for scanning multiple records - rejected for list view
- **Tabbed sections**: Adds JavaScript complexity - rejected for simplicity
- **DataTables.js**: Heavy JS dependency, conflicts with Turbo - rejected

**Implementation Notes**:
```erb
<!-- List view: horizontal scroll wrapper -->
<div class="overflow-x-auto">
  <table class="min-w-full divide-y divide-gray-200">
    <!-- 6-8 key columns visible, scroll for more -->
  </table>
</div>

<!-- Detail view: grouped sections -->
<div class="space-y-6">
  <section class="bg-white rounded-lg shadow p-6">
    <h2 class="text-lg font-semibold mb-4">Customer Information</h2>
    <dl class="grid grid-cols-2 gap-4">
      <!-- Field/value pairs -->
    </dl>
  </section>
  <!-- More sections... -->
</div>
```

**Field Display Groupings** (per spec FR-006):
1. **Customer Info**: soldTo, shipTo, custName, country, region, salesOrg
2. **Order Info**: salesDoc, itemNumber, orderDate, requestedDate, material, quantities
3. **Shipping**: shipType, deliveryNumber, estShipDate, carrier, tracking
4. **Inventory**: inStock, neededQty, shortfalls, warehouse, location
5. **Status/Actions**: orderStatus, actionText, actionDate, actionUser, CSR fields

---

### 4. CSV Export Implementation

**Decision**: Use Ruby's built-in CSV library with streaming response

**Rationale**:
- Ruby CSV library is built-in, no gems needed
- Streaming prevents memory issues with 1000+ records
- Respects current search/filter parameters
- Simple implementation, follows Rails patterns

**Alternatives Considered**:
- **Buffered generation**: Memory issues with large datasets - rejected
- **Background job export**: Overkill for <5 second requirement - rejected
- **Excel export (xlsx)**: Out of scope per spec, adds gem dependency - rejected

**Implementation Notes**:
```ruby
# Controller
def index
  @open_orders = filtered_orders

  respond_to do |format|
    format.html
    format.csv do
      headers['Content-Disposition'] = 'attachment; filename="open_orders.csv"'
      headers['Content-Type'] = 'text/csv'
      self.response_body = csv_enumerator(@open_orders)
    end
  end
end

private

def csv_enumerator(records)
  Enumerator.new do |yielder|
    yielder << CSV.generate_line(OpenOrder::CSV_HEADERS)
    records.find_each do |order|
      yielder << CSV.generate_line(order.to_csv_row)
    end
  end
end
```

---

### 5. Search and Filter Implementation

**Decision**: Simple query scopes with form-based filtering

**Rationale**:
- Rails scopes provide clean, testable query building
- Form submission with GET preserves filters in URL (bookmarkable)
- Turbo Frame for list updates without full page reload
- No complex search gems needed for basic text matching

**Alternatives Considered**:
- **Ransack**: Adds complexity, learning curve - rejected for simplicity
- **Elasticsearch**: Massive overkill for 5000 records - rejected
- **pg_search**: PostgreSQL-specific, using SQLite - rejected

**Implementation Notes**:
```ruby
# Model scopes
class OpenOrder < ApplicationRecord
  scope :by_customer, ->(name) { where("cust_name LIKE ?", "%#{name}%") if name.present? }
  scope :by_sales_doc, ->(doc) { where(sales_doc: doc) if doc.present? }
  scope :by_material, ->(mat) { where("material LIKE ?", "%#{mat}%") if mat.present? }

  def self.filtered(params)
    by_customer(params[:customer])
      .by_sales_doc(params[:sales_doc])
      .by_material(params[:material])
  end
end
```

---

### 6. Sorting Implementation

**Decision**: URL-based sort parameters with column header links

**Rationale**:
- Sort state in URL makes it bookmarkable and shareable
- Works naturally with Turbo/pagination
- Simple to implement with Rails conventions
- Preserves sort across pagination

**Alternatives Considered**:
- **JavaScript table sorting**: Client-side only, doesn't work with pagination - rejected
- **Stimulus controller**: Adds complexity for simple feature - rejected

**Implementation Notes**:
```ruby
# Controller
SORTABLE_COLUMNS = %w[sales_doc cust_name order_date requested_date material order_status].freeze
DEFAULT_SORT = { column: 'order_date', direction: 'desc' }.freeze

def index
  @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT[:column]
  @sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : DEFAULT_SORT[:direction]

  @open_orders = OpenOrder.filtered(filter_params).order("#{@sort_column} #{@sort_direction}")
end

# View helper for sortable headers
def sortable_header(column, title)
  direction = (@sort_column == column && @sort_direction == 'asc') ? 'desc' : 'asc'
  link_to title, request.params.merge(sort: column, direction: direction)
end
```

---

### 7. Turbo/Hotwire Integration

**Decision**: Turbo Frames for pagination and filtering, Turbo Drive for navigation

**Rationale**:
- Turbo Drive enabled by default, provides SPA-like navigation
- Turbo Frames isolate list updates for search/filter/pagination
- No custom JavaScript needed
- Preserves scroll position and filter state naturally

**Alternatives Considered**:
- **Full page reloads**: Slower, worse UX - rejected
- **React/Vue SPA**: Massive overkill, adds complexity - rejected
- **Stimulus-heavy approach**: More code than Turbo Frames - rejected

**Implementation Notes**:
```erb
<!-- index.html.erb -->
<%= turbo_frame_tag "open_orders_list" do %>
  <!-- Search form targets this frame -->
  <%= form_with url: open_orders_path, method: :get, data: { turbo_frame: "open_orders_list" } do |f| %>
    <!-- Filter inputs -->
  <% end %>

  <!-- Table and pagination -->
  <table>...</table>
  <%== pagy_nav(@pagy, pagy_id: 'open_orders_list') %>
<% end %>

<!-- Back button preserves state via Turbo cache -->
```

---

### 8. Database Indexing Strategy

**Decision**: Add indexes on searchable, sortable, and foreign key columns

**Rationale**:
- salesDoc + itemNumber composite index for primary lookups (unique constraint)
- Individual indexes on search fields for filter performance
- Sort column indexes for ORDER BY performance
- Standard Rails convention for lookup fields

**Indexes to Create**:
```ruby
# Migration
add_index :open_orders, [:sales_doc, :item_number], unique: true
add_index :open_orders, :sales_doc
add_index :open_orders, :cust_name
add_index :open_orders, :material
add_index :open_orders, :order_date
add_index :open_orders, :requested_date
add_index :open_orders, :order_status
```

---

## Summary of Decisions

| Topic | Decision | Key Rationale |
|-------|----------|---------------|
| Pagination | Pagy gem | Fast, Turbo-native, simple |
| Authentication | Rails 8 generator | Built-in, no gems, sufficient for admin |
| Table styling | Tailwind + scroll | Simple, no JS dependencies |
| CSV export | Streaming with Ruby CSV | Built-in, memory efficient |
| Search/Filter | Rails scopes + form | Simple, bookmarkable URLs |
| Sorting | URL params + header links | Works with pagination |
| Turbo integration | Frames for list, Drive for nav | SPA-like without JS |
| DB indexes | Composite + individual | Query performance |

## Unresolved Items

None - all technical decisions have been made.
