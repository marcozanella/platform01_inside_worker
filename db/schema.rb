# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_15_120359) do
  create_table "job_log_details", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "job_log_id", null: false
    t.text "message", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_job_log_details_on_created_at"
    t.index ["job_log_id"], name: "index_job_log_details_on_job_log_id"
  end

  create_table "job_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_job_logs_on_created_at"
    t.index ["name"], name: "index_job_logs_on_name", unique: true
    t.index ["status"], name: "index_job_logs_on_status"
  end

  create_table "open_orders", force: :cascade do |t|
    t.date "action_date"
    t.text "action_text"
    t.string "action_user"
    t.string "base_uom"
    t.string "bismt"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "csr_action_date"
    t.text "csr_action_text"
    t.string "csr_action_user"
    t.string "csr_name"
    t.integer "cumu_shortfall"
    t.text "current_text"
    t.string "cust_name"
    t.string "cust_po_num"
    t.text "customer_note"
    t.integer "days_late"
    t.integer "delivery_item_number"
    t.string "delivery_number"
    t.string "equipment"
    t.date "est_ship_date"
    t.string "fert_code"
    t.string "fert_desc"
    t.string "full_name"
    t.integer "gi_qty"
    t.string "gi_qty_uom"
    t.string "i_stloc"
    t.integer "in_stock"
    t.integer "item_number"
    t.integer "leadtime"
    t.string "material"
    t.string "material_description"
    t.string "name1"
    t.integer "needed_qty"
    t.integer "open_del_qty"
    t.string "open_del_qty_uom"
    t.integer "open_order_qty"
    t.string "open_order_qty_uom"
    t.date "order_date"
    t.integer "order_qty"
    t.string "order_qty_uom"
    t.integer "order_shortfall"
    t.string "order_status"
    t.date "pl_gl_date"
    t.integer "plant"
    t.string "process_order_num"
    t.date "requested_date"
    t.string "s_loc"
    t.integer "safety_stock"
    t.string "sales_doc"
    t.string "sales_rep"
    t.string "sales_type"
    t.string "service_agent_name"
    t.string "service_agent_number"
    t.string "ship_status"
    t.string "ship_status_id"
    t.integer "ship_to"
    t.integer "ship_type"
    t.string "shipment_number"
    t.string "shipping_from"
    t.string "shipping_type"
    t.string "so_stloc"
    t.integer "sold_to"
    t.integer "temp_sensitive"
    t.integer "total_shortfall"
    t.integer "transit_time"
    t.string "ud_code"
    t.integer "unrestricted_qty"
    t.string "unrestricted_qty_uom"
    t.datetime "updated_at", null: false
    t.index ["cust_name"], name: "index_open_orders_on_cust_name"
    t.index ["material"], name: "index_open_orders_on_material"
    t.index ["order_date"], name: "index_open_orders_on_order_date"
    t.index ["order_status"], name: "index_open_orders_on_order_status"
    t.index ["sales_doc"], name: "index_open_orders_on_sales_doc"
  end

  add_foreign_key "job_log_details", "job_logs"
end
