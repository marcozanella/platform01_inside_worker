# Rake tasks for OpenOrder data sync
namespace :sync do
  desc "Manually sync OpenOrder data from SQL Server"
  task open_orders: :environment do
    puts "=" * 80
    puts "OpenOrder Sync - Manual Execution"
    puts "=" * 80
    puts ""
    puts "Starting sync at: #{Time.current}"
    puts ""

    begin
      # Execute the job synchronously
      result = SyncOpenOrdersJob.perform_now

      puts ""
      puts "=" * 80
      puts "✓ Sync completed successfully!"
      puts "  Records imported: #{result}"
      puts "  Completed at: #{Time.current}"
      puts "=" * 80

    rescue => e
      puts ""
      puts "=" * 80
      puts "✗ Sync failed!"
      puts "  Error: #{e.class} - #{e.message}"
      puts "  See logs for details"
      puts "=" * 80

      exit 1
    end
  end
end
