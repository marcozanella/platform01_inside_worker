class SyncOpenOrdersJob < ApplicationJob
  queue_as :default

  def perform(*args)
    start_time = Time.current

    # Create job log
    job_log = JobLog.create_with_timestamp!
    job_log.add_detail("Job started - SyncOpenOrdersJob")
    job_log.processing!

    connector = nil
    record_count = 0

    begin
      # Connect to SQL Server and fetch data
      job_log.add_detail("Connecting to SQL Server #{SqlServerConnector::HOST}...")
      connector = SqlServerConnector.new
      job_log.add_detail("Connected successfully")
      Rails.logger.info "[SyncOpenOrdersJob] Connected to SQL Server"

      # Fetch data
      job_log.add_detail("Fetching records from vwZSDOrder_Advanced...")
      sql_rows = connector.execute("SELECT * FROM vwZSDOrder_Advanced WHERE plant=8800")
      job_log.add_detail("Fetched #{sql_rows.size} records")
      Rails.logger.info "[SyncOpenOrdersJob] Fetched #{sql_rows.size} records from SQL Server"

      # Import data (truncate + insert happens in transaction)
      job_log.add_detail("Truncating existing open_orders table...")
      record_count = OpenOrdersImporter.import(sql_rows, job_log)

      # Calculate duration
      duration = (Time.current - start_time).round(2)
      job_log.add_detail("Job completed successfully - Total: #{record_count} records in #{duration} seconds")
      job_log.success!
      Rails.logger.info "[SyncOpenOrdersJob] Sync completed successfully: #{record_count} records imported in #{duration} seconds"

      record_count

    rescue SqlServerConnector::ConnectionError => e
      error_msg = "SQL Server connection failed: #{e.message}"
      job_log&.add_detail("ERROR: #{error_msg}")
      job_log&.error!
      Rails.logger.error "[SyncOpenOrdersJob] #{error_msg}"
      Rails.logger.error "[SyncOpenOrdersJob] Old data preserved in open_orders table"
      raise # Re-raise to allow Solid Queue to retry

    rescue SqlServerConnector::QueryError => e
      error_msg = "SQL Server query failed: #{e.message}"
      job_log&.add_detail("ERROR: #{error_msg}")
      job_log&.error!
      Rails.logger.error "[SyncOpenOrdersJob] #{error_msg}"
      Rails.logger.error "[SyncOpenOrdersJob] Old data preserved in open_orders table"
      raise # Re-raise to allow Solid Queue to retry

    rescue OpenOrdersImporter::ImportError => e
      error_msg = "Import failed: #{e.message}"
      job_log&.add_detail("ERROR: #{error_msg}")
      job_log&.error!
      Rails.logger.error "[SyncOpenOrdersJob] #{error_msg}"
      Rails.logger.error "[SyncOpenOrdersJob] Transaction rolled back, old data preserved"
      raise # Re-raise to allow Solid Queue to retry

    rescue StandardError => e
      error_msg = "Unexpected error: #{e.class} - #{e.message}"
      job_log&.add_detail("ERROR: #{error_msg}")
      job_log&.error!
      Rails.logger.error "[SyncOpenOrdersJob] #{error_msg}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise # Re-raise to allow Solid Queue to retry

    ensure
      # Always close the connection
      connector&.close
    end
  end
end
