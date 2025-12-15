module OpenOrdersHelper
  # Format date consistently across views (YYYY-MM-DD)
  # Returns "—" for nil values
  def format_order_date(date)
    date&.strftime("%Y-%m-%d") || "—"
  end

  # Format datetime with time component (YYYY-MM-DD HH:MM:SS TZ)
  # Returns "—" for nil values
  def format_order_datetime(datetime)
    datetime&.strftime("%Y-%m-%d %H:%M:%S %Z") || "—"
  end

  # Format quantity with unit of measure
  # Returns "—" for nil quantity, just UOM if qty exists but UOM missing
  def format_quantity_with_uom(quantity, uom = nil)
    return "—" if quantity.nil?

    formatted_qty = number_with_delimiter(quantity)
    uom.present? ? "#{formatted_qty} #{uom}" : formatted_qty
  end

  # Display placeholder for null/empty values
  # Returns "—" for nil or empty strings, otherwise returns the value
  def display_value(value, placeholder = "—")
    value.present? ? value : placeholder
  end

  # Format order status with color-coded badge
  # Returns span element with Tailwind CSS classes based on status
  def status_badge(status)
    return content_tag(:span, "—", class: "text-sm text-gray-900") if status.blank?

    badge_class = case status.downcase
    when /open/
                    "bg-green-100 text-green-800"
    when /blocked/
                    "bg-red-100 text-red-800"
    when /partial/
                    "bg-yellow-100 text-yellow-800"
    when /closed/
                    "bg-gray-100 text-gray-800"
    else
                    "bg-blue-100 text-blue-800"
    end

    content_tag(:span, status, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{badge_class}")
  end

  # Sort direction helper - returns opposite direction for toggle
  def toggle_sort_direction(current_direction)
    current_direction == "asc" ? "desc" : "asc"
  end

  # Generate sort link parameters
  def sort_link_params(column, current_sort, current_direction)
    direction = if current_sort == column
                 toggle_sort_direction(current_direction)
    else
                 "asc"
    end

    { sort: column, direction: direction }
  end

  # Display sort indicator (↑ or ↓) for column headers
  def sort_indicator(column, current_sort, current_direction)
    return "" unless current_sort == column

    current_direction == "asc" ? "↑" : "↓"
  end

  # Format last sync timestamp with time ago
  # Returns formatted string with absolute time and relative time
  def format_last_sync_time
    last_sync = OpenOrder.maximum(:updated_at)
    return "Never synced" unless last_sync

    "#{time_ago_in_words(last_sync)} ago (#{last_sync.strftime('%b %d, %Y at %I:%M %p')})"
  end

  # Get sync status based on last sync time
  # Returns hash with status (:synced, :stale, :error) and CSS classes
  def sync_status
    last_sync = OpenOrder.maximum(:updated_at)

    unless last_sync
      return {
        status: :error,
        text: "Never synced",
        icon: "✗",
        color_class: "text-red-600",
        bg_class: "bg-red-50",
        border_class: "border-red-200"
      }
    end

    minutes_since_sync = ((Time.current - last_sync) / 60).to_i

    if minutes_since_sync < 10
      {
        status: :synced,
        text: "Synced",
        icon: "✓",
        color_class: "text-green-600",
        bg_class: "bg-green-50",
        border_class: "border-green-200"
      }
    elsif minutes_since_sync < 30
      {
        status: :stale,
        text: "Stale",
        icon: "⚠",
        color_class: "text-yellow-600",
        bg_class: "bg-yellow-50",
        border_class: "border-yellow-200"
      }
    else
      {
        status: :error,
        text: "Error",
        icon: "✗",
        color_class: "text-red-600",
        bg_class: "bg-red-50",
        border_class: "border-red-200"
      }
    end
  end
end
