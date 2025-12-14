class OpenOrdersController < ApplicationController
  # Simple HTTP Basic Authentication for admin access
  http_basic_authenticate_with name: ENV.fetch("ADMIN_USERNAME", "admin"),
                                password: ENV.fetch("ADMIN_PASSWORD", "password")

  def index
    @open_orders = OpenOrder.all

    # Search/filter functionality (T011)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @open_orders = @open_orders.where(
        "cust_name LIKE ? OR sales_doc LIKE ? OR material LIKE ?",
        search_term, search_term, search_term
      )
      Rails.logger.info "OpenOrders#index: Search performed with term '#{params[:search]}'"
    end

    # Sorting functionality (T012)
    if params[:sort].present?
      sort_column = params[:sort]
      sort_direction = params[:direction] == "desc" ? "desc" : "asc"
      @open_orders = @open_orders.order("#{sort_column} #{sort_direction}")
      Rails.logger.info "OpenOrders#index: Sorted by #{sort_column} #{sort_direction}"
    else
      # Default sort by requested_date descending
      @open_orders = @open_orders.order(requested_date: :desc)
    end

    # Respond to different formats
    respond_to do |format|
      format.html do
        # Pagination (T010) - 50 records per page for HTML view
        @open_orders = @open_orders.page(params[:page]).per(50)

        # Last sync timestamp (placeholder for future sync worker)
        @last_sync = OpenOrder.maximum(:updated_at)

        Rails.logger.info "OpenOrders#index: Displaying page #{params[:page] || 1} with #{@open_orders.size} records"
      end

      format.csv do
        # CSV export limited to 1,000 records (T041-T043)
        @open_orders = @open_orders.limit(1000)
        Rails.logger.info "OpenOrders#index: CSV export requested, exporting #{@open_orders.size} records"
        send_data generate_csv(@open_orders),
                  filename: "open_orders_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                  type: "text/csv"
      end
    end
  end

  def show
    @open_order = OpenOrder.find(params[:id])
    Rails.logger.info "OpenOrders#show: Displaying order #{@open_order.sales_doc} (ID: #{@open_order.id})"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "OpenOrders#show: Order with ID #{params[:id]} not found"
    redirect_to open_orders_path, alert: "Open order not found."
  end

  private

  # Generate CSV data from OpenOrder collection
  def generate_csv(open_orders)
    require "csv"

    CSV.generate(headers: true) do |csv|
      # CSV header row with all important fields
      csv << [
        "Sales Doc", "Item Number", "Customer Name", "Sold To", "Ship To",
        "Country", "Plant", "Material", "Material Description",
        "Order Date", "Requested Date", "Customer PO", "Customer PO Date",
        "Order Qty", "Confirm Qty", "UOM",
        "Order Status", "Sales Type",
        "Shipping Point", "Ship To Plant", "Delivery Number", "Delivery Date",
        "Pick Qty", "Goods Issue Qty", "Shipped Qty",
        "Unrestricted Stock", "Allocated Stock", "Available Stock",
        "Sales Org", "Distribution Channel", "Division",
        "CSR Promised Date", "CSR Promised Quantity",
        "Created By", "Changed By", "Changed Date"
      ]

      # Data rows
      open_orders.each do |order|
        csv << [
          order.sales_doc,
          order.item_number,
          order.cust_name,
          order.sold_to,
          order.ship_to,
          order.country,
          order.plant,
          order.material,
          order.material_description,
          order.order_date&.strftime("%Y-%m-%d"),
          order.requested_date&.strftime("%Y-%m-%d"),
          order.cust_po,
          order.cust_po_date&.strftime("%Y-%m-%d"),
          order.order_qty,
          order.confirm_qty,
          order.uom,
          order.order_status,
          order.sales_type,
          order.shipping_point,
          order.ship_to_plant,
          order.delivery_number,
          order.delivery_date&.strftime("%Y-%m-%d"),
          order.pick_qty,
          order.goods_issue_qty,
          order.shipped_qty,
          order.unrestricted_stock,
          order.allocated_stock,
          order.available_stock,
          order.sales_org,
          order.distribution_channel,
          order.division,
          order.csr_promised_date&.strftime("%Y-%m-%d"),
          order.csr_promised_quantity,
          order.created_by,
          order.changed_by,
          order.changed_date&.strftime("%Y-%m-%d")
        ]
      end
    end
  end
end
