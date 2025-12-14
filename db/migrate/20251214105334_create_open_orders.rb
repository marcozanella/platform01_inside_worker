class CreateOpenOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :open_orders do |t|
      t.integer :sold_to
      t.integer :ship_to
      t.string :cust_name
      t.string :country
      t.integer :plant
      t.string :sales_doc
      t.string :so_stloc
      t.integer :item_number
      t.string :sales_type
      t.date :order_date
      t.date :requested_date
      t.integer :transit_time
      t.date :pl_gl_date
      t.integer :days_late
      t.string :material
      t.string :material_description
      t.integer :order_qty
      t.string :order_qty_uom
      t.integer :open_order_qty
      t.string :open_order_qty_uom
      t.integer :open_del_qty
      t.string :open_del_qty_uom
      t.integer :gi_qty
      t.string :gi_qty_uom
      t.integer :in_stock
      t.integer :needed_qty
      t.integer :order_shortfall
      t.string :equipment
      t.string :i_stloc
      t.integer :ship_type
      t.string :process_order_num
      t.string :csr_name
      t.string :order_status
      t.string :ud_code
      t.string :fert_code
      t.string :fert_desc
      t.integer :safety_stock
      t.string :base_uom
      t.string :s_loc
      t.integer :unrestricted_qty
      t.string :unrestricted_qty_uom
      t.date :est_ship_date
      t.string :ship_status
      t.text :action_text
      t.date :action_date
      t.string :action_user
      t.integer :cumu_shortfall
      t.integer :total_shortfall
      t.string :ship_status_id
      t.integer :leadtime
      t.string :delivery_number
      t.integer :delivery_item_number
      t.string :shipment_number
      t.string :service_agent_number
      t.string :sales_rep
      t.string :service_agent_name
      t.string :cust_po_num
      t.text :customer_note
      t.string :shipping_from
      t.string :name1
      t.string :full_name
      t.text :current_text
      t.string :bismt
      t.string :shipping_type
      t.integer :temp_sensitive
      t.text :csr_action_text
      t.string :csr_action_date
      t.string :csr_action_user

      t.timestamps
    end

    # Add indexes for frequently searched/sorted fields
    add_index :open_orders, :sales_doc
    add_index :open_orders, :cust_name
    add_index :open_orders, :order_date
    add_index :open_orders, :material
    add_index :open_orders, :order_status
  end
end
