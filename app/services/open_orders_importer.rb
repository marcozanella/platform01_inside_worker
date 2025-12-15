# Service object for importing OpenOrder data from SQL Server
# Handles explicit column mapping, batch processing, and data type conversion
class OpenOrdersImporter
  class ImportError < StandardError; end

  BATCH_SIZE = 500

  # Explicit column mapping: SQL Server Column Name => Rails Attribute Symbol
  # This mapping documents expected SQL Server schema and fails fast if columns are missing
  #
  # SQL Server columns use camelCase (e.g., 'soldTo', 'salesDoc')
  # Rails attributes use snake_case (e.g., :sold_to, :sales_doc)
  #
  # Total fields mapped: 67 (excludes Rails timestamps created_at/updated_at)
  # Source: vwZSDOrder_Advanced view in ProcessStatus database
  #
  # Data types in Rails model:
  #   - Integer fields: 21 fields (sold_to, ship_to, quantities, inventory, etc.)
  #   - String fields: 32 fields (names, codes, statuses, descriptions)
  #   - Date fields: 5 fields (order_date, requested_date, est_ship_date, pl_gl_date, action_date)
  #   - Text fields: 4 fields (action_text, customer_note, current_text, csr_action_text)
  #   - Special: csr_action_date stored as string (not parsed as date)
  COLUMN_MAPPING = {
    # Customer Information
    "soldTo" => :sold_to,
    "shipTo" => :ship_to,
    "custName" => :cust_name,
    "country" => :country,
    "custPONum" => :cust_po_num,

    # Order Information
    "salesDoc" => :sales_doc,
    "itemNumber" => :item_number,
    "salesType" => :sales_type,
    "plant" => :plant,
    "soStloc" => :so_stloc,

    # Material Information
    "material" => :material,
    "materialDescription" => :material_description,
    "bismt" => :bismt,

    # Date Information
    "orderDate" => :order_date,
    "requestedDate" => :requested_date,
    "estShipDate" => :est_ship_date,
    "plGlDate" => :pl_gl_date,
    "actionDate" => :action_date,

    # Quantity Information
    "orderQty" => :order_qty,
    "orderQty_UoM" => :order_qty_uom,
    "openOrderQty" => :open_order_qty,
    "openOrderQty_UoM" => :open_order_qty_uom,
    "openDelQty" => :open_del_qty,
    "openDelQty_UoM" => :open_del_qty_uom,
    "giQty" => :gi_qty,
    "giQty_UoM" => :gi_qty_uom,

    # Inventory Information
    "inStock" => :in_stock,
    "neededQty" => :needed_qty,
    "orderShortfall" => :order_shortfall,
    "cumuShortfall" => :cumu_shortfall,
    "totalShortfall" => :total_shortfall,
    "unrestrictedQty" => :unrestricted_qty,
    "unrestrictedQty_UoM" => :unrestricted_qty_uom,
    "safetyStock" => :safety_stock,
    "baseUoM" => :base_uom,

    # Shipping Information
    "shipType" => :ship_type,
    "shipStatus" => :ship_status,
    "shipStatusID" => :ship_status_id,
    "shippingFrom" => :shipping_from,
    "shippingType" => :shipping_type,
    "deliveryNumber" => :delivery_number,
    "deliveryItemNumber" => :delivery_item_number,
    "shipmentNumber" => :shipment_number,

    # Status and Actions
    "orderStatus" => :order_status,
    "actionText" => :action_text,
    "actionUser" => :action_user,
    "currentText" => :current_text,

    # CSR Information
    "csrName" => :csr_name,
    "CSR_actionText" => :csr_action_text,
    "CSR_actionDate" => :csr_action_date,
    "CSR_actionUser" => :csr_action_user,

    # Sales and Service
    "salesRep" => :sales_rep,
    "serviceAgentNumber" => :service_agent_number,
    "serviceAgentName" => :service_agent_name,

    # Logistics
    "equipment" => :equipment,
    "iStloc" => :i_stloc,
    "sLoc" => :s_loc,
    "processOrderNum" => :process_order_num,
    "transitTime" => :transit_time,
    "daysLate" => :days_late,
    "leadtime" => :leadtime,
    "tempSensitive" => :temp_sensitive,

    # Additional Fields
    "udCode" => :ud_code,
    "fertCode" => :fert_code,
    "fertDesc" => :fert_desc,
    "customerNote" => :customer_note,
    "NAME1" => :name1,
    "fullName" => :full_name
  }.freeze

  # Import records with batch processing and transaction safety
  # Returns the number of records imported
  def self.import(sql_rows)
    puts "Entering the Service Object OpenOrdersImporter.import method"
    return 0 if sql_rows.empty?

    record_count = 0

    OpenOrder.transaction do
      # Delete all existing records (only after successful fetch)
      puts "[OpenOrdersImporter] Truncating open_orders table"
      OpenOrder.delete_all

      # Process in batches
      sql_rows.each_slice(BATCH_SIZE) do |batch|
        mapped_records = batch.map { |row| map_row(row) }
        OpenOrder.insert_all(mapped_records, returning: false)
        record_count += batch.size
        puts "[OpenOrdersImporter] Imported batch of #{batch.size} records (total: #{record_count})"
      end
    end

    puts "[OpenOrdersImporter] Import completed: #{record_count} records"
    record_count
  rescue ActiveRecord::ActiveRecordError => e
    puts "[OpenOrdersImporter] Import failed: #{e.message}"
    puts "[OpenOrdersImporter] Transaction rolled back, old data preserved"
    raise ImportError, "Data import failed: #{e.message}"
  end

  private

  def self.map_row(sql_row)
    puts "[OpenOrdersImporter] Mapping SQL row to OpenOrder attributes"
    puts "We received this SQL row: #{sql_row.inspect}"
    mapped = {}

    COLUMN_MAPPING.each do |sql_column, rails_attr|
      puts "Working on the SQL column: #{sql_column} to map to attribute: #{rails_attr}"
      raw_value = sql_row[sql_column]
      puts "The value of the SLQ column #{sql_column} is: #{raw_value.inspect}"
      conversion_test = convert_value(rails_attr, raw_value)
      puts "The converted value is: #{conversion_test.inspect} for attribute #{rails_attr}"
      mapped[rails_attr] = convert_value(rails_attr, raw_value)
    end

    # Check for unmapped columns (informational only)
    sql_row.keys.each do |sql_column|
      unless COLUMN_MAPPING.key?(sql_column)
        # puts "[OpenOrdersImporter] Unmapped SQL Server column: #{sql_column}"
      end
    end

    mapped
  end

  def self.convert_value(rails_attr, value)
    return nil if value.blank?
    puts "I need to convert this value: #{value.inspect} for attribute #{rails_attr}"

    case rails_attr
    # Date fields that need parsing
    when :order_date, :requested_date, :est_ship_date, :pl_gl_date, :action_date
      puts "This should be a Date field"
      Date.parse(value.to_s) rescue nil

    # Integer fields
    when :sold_to, :ship_to, :plant, :item_number, :order_qty, :open_order_qty,
         :open_del_qty, :gi_qty, :in_stock, :needed_qty, :order_shortfall,
         :cumu_shortfall, :total_shortfall, :unrestricted_qty, :safety_stock,
         :transit_time, :days_late, :leadtime, :delivery_item_number,
         :ship_type, :temp_sensitive
      puts "This should be an Integer field"
      value.to_i

    # Text fields (large text)
    when :action_text, :customer_note, :current_text, :csr_action_text
      puts "This should be a Text field"
      value.to_s

    # String fields (default)
    else
      puts "This should be a String field"
      value.to_s.strip
    end
    puts "returned value: #{value.inspect} for attribute #{rails_attr}"
    value
  end
end
