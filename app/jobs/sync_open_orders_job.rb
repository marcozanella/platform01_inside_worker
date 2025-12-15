class SyncOpenOrdersJob < ApplicationJob
  queue_as :default

  def perform(*args)
    start_time = Time.current
    Rails.logger.info "[SyncOpenOrdersJob] Sync started at #{start_time}"

    connector = nil
    record_count = 0

    begin
      # Connect to SQL Server and fetch data
      connector = SqlServerConnector.new
      Rails.logger.info "[SyncOpenOrdersJob] Fetching records from vwZSDOrder_Advanced"

      sql_rows = connector.execute("SELECT * FROM vwZSDOrder_Advanced WHERE plant=8800")
      Rails.logger.info "[SyncOpenOrdersJob] Fetched #{sql_rows.size} records from SQL Server"

      if sql_rows
        log_counter = 0
        sql_rows.each do |row|
          puts "=[SyncOpenOrdersJob] Sample Row #{log_counter + 1} Data:"
          row.each do |key, value|
            puts "[SyncOpenOrdersJob] Row data - #{key}: #{value.inspect}"
          end
          log_counter += 1
          break if log_counter >= 1 # Log only the first 1 rows for brevity
        end
      end

      # Import data (truncate + insert happens in transaction)
      record_count = OpenOrdersImporter.import(sql_rows)

      # Calculate duration
      duration = (Time.current - start_time).round(2)
      Rails.logger.info "[SyncOpenOrdersJob] ✓ Sync completed successfully: #{record_count} records imported in #{duration} seconds"

      record_count

    rescue SqlServerConnector::ConnectionError => e
      Rails.logger.error "[SyncOpenOrdersJob] ✗ Connection failed: #{e.message}"
      Rails.logger.error "[SyncOpenOrdersJob] Old data preserved in open_orders table"
      raise # Re-raise to allow Solid Queue to retry

    rescue SqlServerConnector::QueryError => e
      Rails.logger.error "[SyncOpenOrdersJob] ✗ Query failed: #{e.message}"
      Rails.logger.error "[SyncOpenOrdersJob] Old data preserved in open_orders table"
      raise # Re-raise to allow Solid Queue to retry

    rescue OpenOrdersImporter::ImportError => e
      Rails.logger.error "[SyncOpenOrdersJob] ✗ Import failed: #{e.message}"
      Rails.logger.error "[SyncOpenOrdersJob] Transaction rolled back, old data preserved"
      raise # Re-raise to allow Solid Queue to retry

    rescue StandardError => e
      Rails.logger.error "[SyncOpenOrdersJob] ✗ Unexpected error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise # Re-raise to allow Solid Queue to retry

    ensure
      # Always close the connection
      connector&.close
    end
  end
end
