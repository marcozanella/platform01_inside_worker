# Feature Specification: OpenOrder View Interface

**Feature Branch**: `001-openorder-crud`  
**Created**: 2025-12-13  
**Status**: Draft  
**Input**: User description: "A CRUD flow to manage the model OpenOrder with 70+ fields from SQL Server view" (updated to read-only view interface)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View OpenOrder List (Priority: P1)

Admin logs into the application and views a paginated list of OpenOrder records to monitor current order status and identify issues requiring attention.

**Why this priority**: Viewing existing orders is the foundation of order management. Admins need visibility into the data before they can take any action. This is the minimum viable product.

**Independent Test**: Admin can navigate to /open_orders, see a list of orders with key fields (sales doc, customer name, order date, status, material), paginate through results, and sort by common fields (order date, requested date, status).

**Acceptance Scenarios**:

1. **Given** admin is logged in, **When** they navigate to the OpenOrders index page, **Then** they see a paginated list of orders showing sales document, customer name, plant, material, order status, and requested date
2. **Given** there are more than 50 orders, **When** admin views the list, **Then** pagination controls appear and show 50 records per page
3. **Given** admin is viewing the order list, **When** they click a column header, **Then** the list sorts by that column in ascending/descending order
4. **Given** admin is viewing the order list, **When** they enter search criteria (customer name, sales doc, material), **Then** the list filters to matching records

---

### User Story 2 - View OpenOrder Details (Priority: P1)

Admin clicks on an order from the list to view complete details including all 70+ fields to investigate order status, shipping information, and inventory levels.

**Why this priority**: After identifying an order of interest in the list, admins need to see complete details to understand the full context and make decisions. This completes the Read functionality.

**Independent Test**: Admin can click any order in the list, navigate to a detail page showing all order fields organized in logical groups (customer info, order info, shipping, inventory, status), and return to the list.

**Acceptance Scenarios**:

1. **Given** admin is viewing the order list, **When** they click on a sales document link, **Then** they navigate to the detail page showing all order fields
2. **Given** admin is on the order detail page, **When** the page loads, **Then** fields are organized into sections: Customer Info (soldTo, shipTo, custName, country), Order Info (salesDoc, orderDate, requestedDate, material, quantities), Shipping (shipType, estShipDate, deliveryNumber), Inventory (inStock, neededQty, shortfalls), and Status/Actions
3. **Given** admin is viewing order details, **When** they click "Back to List", **Then** they return to the order list preserving their previous filters and page position

---

### Edge Cases

- How does the system handle viewing orders with null or missing values in optional fields?
- What happens when the order list is empty (no records)?
- How does pagination behave when there are exactly 50, 51, or 0 records?
- How does the system handle very long text values in display fields (actionText, CSR_actionText, customerNote)?
- How does sorting behave when multiple records have the same value in the sorted column?
- What happens if an order is synced while an admin is viewing its detail page?
- How does the UI indicate when data was last synced from SQL Server?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a paginated list view of OpenOrder records showing key fields (salesDoc, custName, orderDate, requestedDate, material, orderStatus)
- **FR-002**: System MUST display 50 records per page by default with pagination controls
- **FR-003**: System MUST allow sorting the order list by any displayed column (ascending and descending)
- **FR-004**: System MUST provide search/filter functionality for customer name, sales document number, and material
- **FR-005**: System MUST provide a detail view showing all 70+ fields of an OpenOrder record
- **FR-006**: System MUST organize the detail view into logical sections (Customer, Order, Shipping, Inventory, Status)
- **FR-007**: System MUST preserve search filters and pagination state when navigating from list to detail and back
- **FR-008**: System MUST handle null/empty values gracefully in optional fields, displaying appropriate placeholders
- **FR-009**: System MUST require admin authentication to access any OpenOrder view functionality
- **FR-010**: System MUST use RESTful routes following Rails conventions (/open_orders, /open_orders/:id for read-only access)
- **FR-011**: System MUST use Hotwire/Turbo for seamless page transitions without full page reloads
- **FR-012**: System MUST style the interface using Tailwind CSS with clean, functional admin UI design
- **FR-013**: System MUST display sync status information (last sync time, sync source) on list and detail pages
- **FR-014**: System MUST clearly indicate that OpenOrder data is read-only (no edit/create/delete buttons visible)
- **FR-015**: System MUST export displayed data to CSV format for offline analysis

### Key Entities

- **OpenOrder**: Represents a sales order record synced from SQL Server's vwZSDOrder_Advanced view. Contains 70+ fields covering customer information (soldTo, shipTo, custName, country), order details (salesDoc, itemNumber, orderDate, material, quantities), shipping information (shipType, deliveryNumber, estShipDate), inventory data (inStock, neededQty, shortfalls), and status tracking (orderStatus, actionText, actionDate, actionUser, CSR actions). Primary identifier is salesDoc + itemNumber. This entity is read-only in the admin interface and populated exclusively by a background worker that syncs data from SQL Server. SQL Server (fed by SAP) is the system of record.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Admin can view a list of orders, navigate to details, and return to the list in under 10 seconds per order
- **SC-002**: The order list page loads and displays 50 records in under 3 seconds
- **SC-003**: Search and filter operations return results in under 2 seconds
- **SC-004**: The interface displays correctly on common admin browsers (Chrome, Firefox, Safari, Edge) without layout issues
- **SC-005**: Pagination correctly displays all records when navigating through large datasets (1,500+ records)
- **SC-006**: Admin can locate a specific order using search and view its details in under 30 seconds
- **SC-007**: Sync status information (last sync timestamp) is visible on all pages
- **SC-008**: CSV export of filtered order list completes in under 5 seconds for up to 1,000 records
- **SC-009**: All 70+ fields are clearly labeled and organized for easy reading
- **SC-010**: Zero confusion about read-only nature (no misleading edit/create buttons present)

## Assumptions

1. **Authentication**: Basic authentication mechanism (HTTP basic auth or simple login) is sufficient for admin access - no complex role-based permissions needed
2. **Data Source**: All OpenOrder records come exclusively from SQL Server sync worker (future implementation) - no manual data entry in this interface
3. **Read-Only Access**: Admins can only view OpenOrder data; SQL Server (fed by SAP) is the authoritative system of record
4. **Concurrent Access**: Low concurrency expected (1-5 admins max) with read-only access - no locking needed
5. **Data Volume**: System will handle up to 5,000 OpenOrder records initially, pagination keeps query performance acceptable
6. **Sync Worker**: A separate background worker feature will be implemented to fetch and sync data from SQL Server on a recurring schedule
7. **Data Freshness**: Sync status displayed to admins; manual refresh triggers are out of scope
8. **Browser Support**: Modern browsers only (last 2 versions of Chrome, Firefox, Safari, Edge) - no IE support needed
9. **Mobile Access**: Not required - admin UI targets desktop/laptop browsers only
10. **Performance**: Standard Rails query optimization (indexes on foreign keys and search fields) sufficient; no caching required initially

## Dependencies

- Rails 8 application with Active Record configured (per constitution)
- Tailwind CSS configured for styling (per constitution)
- Hotwire/Turbo for enhanced interactivity (per constitution)
- Basic authentication system for admin access
- OpenOrder model and database migration (to be created as part of this feature)
- Database indexes on frequently searched/sorted fields (salesDoc, custName, orderDate, material, orderStatus)

## Out of Scope

- Integration with SQL Server sync process (separate feature - will be implemented as background worker)
- Create, Update, Delete operations for OpenOrder records (data is read-only, synced from SQL Server)
- Manual data entry or editing of any OpenOrder fields
- Bulk operations on OpenOrder data
- Export functionality beyond basic CSV (Excel, PDF formats)
- Advanced search with multiple criteria combinations
- Audit trail viewing in UI (logs exist but no UI to view them)
- Email notifications for order status changes
- Order analytics or reporting dashboards
- API endpoints for external systems
- Mobile-responsive design
- Real-time updates when other admins make changes
- Manual sync triggers or sync scheduling configuration
- Field-level access control or permissions
- Custom validation rules (not applicable for read-only data)
- Integration with external shipping or inventory systems
- Data export formatting or templates
