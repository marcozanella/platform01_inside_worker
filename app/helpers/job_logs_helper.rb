module JobLogsHelper
  def status_badge(status)
    case status
    when "success"
      content_tag(:span, "Success", class: "inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-green-100 text-green-800")
    when "error"
      content_tag(:span, "Error", class: "inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-red-100 text-red-800")
    when "processing"
      content_tag(:span, "Processing", class: "inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-yellow-100 text-yellow-800")
    when "pending"
      content_tag(:span, "Pending", class: "inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-gray-100 text-gray-800")
    else
      content_tag(:span, status.humanize, class: "inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-gray-100 text-gray-800")
    end
  end
end
