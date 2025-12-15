# Data Model: SQL Server Column Mapping

**Feature**: 002-sqlserver-sync-worker  
**Date**: 2025-12-14  
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the explicit column mapping between SQL Server's `vwZSDOrder_Advanced` view and the Rails `OpenOrder` model. The mapping handles 67 fields (excluding Rails timestamps) with data type conversions and NULL handling.

---

## Column Mapping Configuration

### Complete Mapping Hash

This configuration will be implemented in `app/services/open_orders_importer.rb`:

```ruby
# app/services/open_orders_importer.rb
class OpenOrdersImporter
  # Explicit column mapping: SQL Server Column Name => Rails Attribute Symbol
  # This mapping documents expected SQL Server schema and fails fast if columns are missing
  COLUMN_MAPPING = {
    # Customer Information
    'SoldTo' => :sold_to,
    'ShipTo' => :ship_to,
    'CustName' => :cust_name,
    'Country' => :country,
    'CustPONum' => :cust_po_num,
    
    # Order Information
    'SalesDoc' => :sales_doc,
    'ItemNumber' => :item_number,
    'SalesType' => :sales_type,
    'Plant' => :plant,
    'SOStloc' => :so_stloc,
    
    # Material Information
    'Material' => :material,
    'MaterialDescription' => :material_description,
    'BISMT' => :bismt,
    
    # Date Information
    'OrderDate' => :order_date,
    'RequestedDate' => :requested_date,
    'EstShipDate' => :est_ship_date,
    'PLGLDate' => :pl_gl_date,
    'ActionDate' => :action_date,
    
    # Quantity Information  
    'OrderQty' => :order_qty,
    'OrderQtyUOM' => :order_qty_uom,
    'OpenOrderQty' => :open_order_qty,
    'OpenOrderQtyUOM' => :open_order_qty_uom,
    'OpenDelQty' => :open_del_qty,
    'OpenDelQtyUOM' => :open_del_qty_uom,
    'GIQty' => :gi_qty,
    'GIQtyUOM' => :gi_qty_uom,
    
    # Inventory Information
    'InStock' => :in_stock,
    'NeededQty' => :needed_qty,
    'OrderShortfall' => :order_shortfall,
    'CumuShortfall' => :cumu_shortfall,
    'TotalShortfall' => :total_shortfall,
    'UnrestrictedQty' => :unrestricted_qty,
    'UnrestrictedQtyUOM' => :unrestricted_qty_uom,
    'SafetyStock' => :safety_stock,
    'BaseUOM' => :base_uom,
    
    # Shipping Information
    'ShipType' => :ship_type,
    'ShipStatus' => :ship_status,
    'ShipStatusID' => :ship_status_id,
    'ShippingFrom' => :shipping_from,
    'ShippingType' => :shipping_type,
    'DeliveryNumber' => :delivery_number,
    'DeliveryItemNumber' => :delivery_item_number,
    'ShipmentNumber' => :shipment_number,
    
    # Status and Actions
    'OrderStatus' => :order_status,
    'ActionText' => :action_text,
    'ActionUser' => :action_user,
    'CurrentText' => :current_text,
    
    # CSR Information
    'CSRName' => :csr_name,
    'CSRActionText' => :csr_action_text,
    'CSRActionDate' => :csr_action_date,
    'CSRActionUser' => :csr_action_user,
    
    # Sales and Service
    'SalesRep' => :sales_rep,
    'ServiceAgentNumber' => :service_agent_number,
    'ServiceAgentName' => :service_agent_name,
    
    # Logistics
    'Equipment' => :equipment,
    'IStloc' => :i_stloc,
    'SLoc' => :s_loc,
    'ProcessOrderNum' => :process_order_num,
    'TransitTime' => :transit_time,
    'DaysLate' => :days_late,
    'Leadtime' => :leadtime,
    'TempSensitive' => :temp_sensitive,
    
    # Additional Fields
    'UDCode' => :ud_code,
    'FertCode' => :fert_code,
    'FertDesc' => :fert_desc,
    'CustomerNote' => :customer_note,
    'Name1' => :name1,
    'FullName' => :full_name,
  }.freeze

  # Rails timestamps (created_at, updated_at) are managed automatically
  # and should NOT be included in the mapping
end
```

---

## Data Type Conversions

### Date Fields

SQL Server dates need to be parsed and converted to Ruby Date objects:

```ruby
def convert_date(value)
  return nil if value.blank?
  Date.parse(value.to_s) rescue nil
end
```

**Date Fields**:
- `order_date`, `requested_date`, `est_ship_date`, `pl_gl_date`, `action_date`
- **Note**: `csr_action_date` is stored as string in Rails model (no conversion needed)

### Integer Fields

SQL Server integers map directly to Ruby integers, but handle NULL:

```ruby
def convert_integer(value)
  return nil if value.blank?
  value.to_i
end
```

**Integer Fields**:
- `sold_to`, `ship_to`, `plant`, `item_number`, `ship_type`
- `order_qty`, `open_order_qty`, `open_del_qty`, `gi_qty`
- `in_stock`, `needed_qty`, `order_shortfall`, `cumu_shortfall`, `total_shortfall`
- `unrestricted_qty`, `safety_stock`, `transit_time`, `days_late`, `leadtime`
- `delivery_item_number`, `temp_sensitive`

### String Fields

SQL Server strings (VARCHAR, NVARCHAR) map directly to Ruby strings:

```ruby
def convert_string(value)
  value.to_s.strip if value.present?
end
```

**String Fields**: All remaining fields not categorized above

### Text Fields (Large Text)

SQL Server TEXT/NTEXT fields map to Rails text columns:

```ruby
def convert_text(value)
  value.to_s if value.present?
end
```

**Text Fields**: `action_text`, `customer_note`, `current_text`, `csr_action_text`

---

## Mapping Implementation

### Import Service Object

```ruby
# app/services/open_orders_importer.rb
class OpenOrdersImporter
  BATCH_SIZE = 500

  def self.import(sql_rows)
    return 0 if sql_rows.empty?
    
    record_count = 0
    
    OpenOrder.transaction do
      # Delete all existing records (only after successful fetch)
      OpenOrder.delete_all
      
      # Process in batches
      sql_rows.each_slice(BATCH_SIZE) do |batch|
        mapped_records = batch.map { |row| map_row(row) }
        OpenOrder.insert_all(mapped_records, returning: false)
        record_count += batch.size
        Rails.logger.info "Imported batch of #{batch.size} records (total: #{record_count})"
      end
    end
    
    record_count
  rescue => e
    Rails.logger.error "Import failed: #{e.message}"
    raise # Re-raise to trigger job retry
  end

  private

  def self.map_row(sql_row)
    COLUMN_MAPPING.transform_values do |rails_attr|
      sql_column = COLUMN_MAPPING.key(rails_attr)
      raw_value = sql_row[sql_column]
      convert_value(rails_attr, raw_value)
    end
  end

  def self.convert_value(rails_attr, value)
    return nil if value.blank?

    case rails_attr
    when :order_date, :requested_date, :est_ship_date, :pl_gl_date, :action_date
      Date.parse(value.to_s) rescue nil
    when :sold_to, :ship_to, :plant, :item_number, :order_qty, :open_order_qty,
         :open_del_qty, :gi_qty, :in_stock, :needed_qty, :order_shortfall,
         :cumu_shortfall, :total_shortfall, :unrestricted_qty, :safety_stock,
         :transit_time, :days_late, :leadtime, :delivery_item_number,
         :ship_type, :temp_sensitive
      value.to_i
    when :action_text, :customer_note, :current_text, :csr_action_text
      value.to_s # Text fields
    else
      value.to_s.strip # String fields
    end
  end
end
```

---

## NULL Handling

### Strategy

- SQL Server NULL values are converted to Ruby `nil`
- Rails handles `nil` values gracefully in database inserts
- View layer (OpenOrdersHelper) displays "—" placeholder for nil values
- No validation errors on NULL values (data from SAP is trusted)

### NULL Scenarios

| Scenario | Handling |
|----------|----------|
| Optional fields (e.g., `customer_note`) | Accept NULL, store as nil |
| Date fields with NULL | Convert to nil (no default date) |
| Numeric fields with NULL | Convert to nil (not zero) |
| String fields with NULL | Convert to nil (not empty string) |

---

## Validation Rules

### No ActiveRecord Validations

Per constitution (Simplicity Over Optimization) and clarifications:
- No `validates` statements in OpenOrder model
- Data from SAP SQL Server is trusted (already validated)
- If SQL Server has bad data, it flows through to Rails
- Troubleshooting happens at SQL Server level, not Rails level

### Data Integrity

Integrity is ensured by:
1. **Database transaction**: All-or-nothing import
2. **Explicit mapping**: Fails if column missing
3. **Type conversion with rescue**: Graceful handling of parse errors
4. **Logging**: All errors logged with context

---

## Transaction Flow

### Sync Sequence

```
1. Job Starts
   ↓
2. Connect to SQL Server
   ↓
3. Execute SELECT query → fetch all rows (outside transaction)
   ↓
4. [If fetch fails, stop here - old data preserved]
   ↓
5. Begin Transaction
   ↓
6. OpenOrder.delete_all
   ↓
7. Process rows in batches of 500
   ↓
8. OpenOrder.insert_all(batch)
   ↓
9. Commit Transaction
   ↓
10. Update timestamp (sync successful)
```

### Rollback Scenarios

| Error Point | Result |
|-------------|--------|
| Connection fails (step 2) | No transaction started, old data preserved |
| Query fails (step 3) | No transaction started, old data preserved |
| Transaction fails (step 6-8) | Automatic rollback, old data preserved |
| Insert fails (step 8) | Automatic rollback, old data preserved |

---

## Schema Assumptions

### SQL Server View Structure

The mapping assumes `vwZSDOrder_Advanced` has columns matching the left side of `COLUMN_MAPPING`. If SQL Server schema differs:

1. **Missing columns**: Import logs warning, uses nil for that field
2. **Extra columns**: Ignored (not mapped)
3. **Renamed columns**: Requires updating COLUMN_MAPPING
4. **Type mismatches**: Conversion attempts, logs error if fails

### Rails Model Structure

The mapping targets the existing OpenOrder model with 67 fields. Model has:
- All fields from migration (no additional migrations needed)
- 5 indexes (sales_doc, cust_name, order_date, material, order_status)
- Rails managed timestamps (created_at, updated_at)

---

## Testing Approach

### Manual Validation (per constitution)

1. **Connection Test**: Verify SQL Server connection succeeds
2. **Column Mapping Test**: Check all 67 columns map correctly
3. **NULL Handling Test**: Verify NULL values don't cause errors
4. **Date Conversion Test**: Verify dates parse correctly
5. **Batch Processing Test**: Verify 500-record batches work
6. **Transaction Test**: Verify rollback on error
7. **Empty Result Test**: Verify handles zero records
8. **Large Dataset Test**: Verify handles 5,000 records

**Test Data**: Use real SQL Server data for validation (no fixtures, no mocks)

---

## Next Steps

1. Implement `OpenOrdersImporter` service with column mapping
2. Implement `SqlServerConnector` service for SQL Server queries
3. Implement `SyncOpenOrdersJob` orchestrating the sync
4. Update `config/database.yml` with SQL Server connection
5. Update `config/recurring.yml` with 5-minute schedule
6. Create `lib/tasks/sync.rake` for manual testing

**Status**: Phase 1 data model complete ✅ - Column mapping defined, ready for implementation.
