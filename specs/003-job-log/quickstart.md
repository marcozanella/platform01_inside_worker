# Quickstart Guide: Job Execution Logging

**Feature**: 003-job-log | **Date**: 2025-12-15

This guide provides step-by-step instructions for implementing, testing, and using the Job Execution Logging feature.

## Prerequisites

- Rails 8.1.1 application running
- SQLite3 database configured
- Solid Queue configured and running
- Existing SyncOpenOrdersJob functional

## Implementation Steps

### 1. Generate Models

```bash
# Generate JobLog model
bin/rails g model JobLog name:string:uniq status:integer:index

# Generate JobLogDetail model  
bin/rails g model JobLogDetail job_log:references message:text
```

### 2. Edit Migrations

**Edit `db/migrate/YYYYMMDDHHMMSS_create_job_logs.rb`**:

```ruby
class CreateJobLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :job_logs do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :job_logs, :name, unique: true
    add_index :job_logs, :status
    add_index :job_logs, :created_at
  end
end
```

**Edit `db/migrate/YYYYMMDDHHMMSS_create_job_log_details.rb`**:

```ruby
class CreateJobLogDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :job_log_details do |t|
      t.references :job_log, null: false, foreign_key: true
      t.text :message, null: false
      t.timestamps
    end

    add_index :job_log_details, :created_at
  end
end
```

### 3. Run Migrations

```bash
bin/rails db:migrate
```

### 4. Configure Models

**`app/models/job_log.rb`**:

```ruby
class JobLog < ApplicationRecord
  has_many :job_log_details, dependent: :destroy
  
  enum :status, { new: 0, processing: 1, error: 2, success: 3 }
  
  validates :name, presence: true, uniqueness: true, 
            format: { with: /\A\d{14}(_\d+)?\z/, message: "must be YYYYMMDDhhmmss format" }
  validates :status, presence: true
  
  # Create log with collision handling
  def self.create_with_timestamp!(time = Time.current)
    base_name = time.strftime("%Y%m%d%H%M%S")
    suffix = 0
    
    loop do
      name = suffix.zero? ? base_name : "#{base_name}_#{suffix}"
      begin
        return create!(name: name, status: :new)
      rescue ActiveRecord::RecordNotUnique
        suffix += 1
        raise "Too many collisions" if suffix > 100
      end
    end
  end
  
  # Helper to add log detail
  def add_detail(message)
    job_log_details.create!(message: message)
  end
end
```

**`app/models/job_log_detail.rb`**:

```ruby
class JobLogDetail < ApplicationRecord
  belongs_to :job_log
  
  validates :message, presence: true, length: { maximum: 5000 }
  
  default_scope { order(created_at: :asc) }
end
```

### 5. Generate Controller

```bash
bin/rails g controller JobLogs index show
```

**`app/controllers/job_logs_controller.rb`**:

```ruby
class JobLogsController < ApplicationController
  # Inherit authentication from ApplicationController
  http_basic_authenticate_with name: ENV.fetch("ADMIN_USERNAME", "admin"),
                                password: ENV.fetch("ADMIN_PASSWORD", "password")
  
  def index
    @job_logs = JobLog.order(created_at: :desc).page(params[:page]).per(25)
  end
  
  def show
    @job_log = JobLog.find(params[:id])
    @job_log_details = @job_log.job_log_details # Already ordered by created_at
  end
end
```

### 6. Update Routes

**`config/routes.rb`**:

```ruby
Rails.application.routes.draw do
  # Job logs as root
  root "job_logs#index"
  
  # Job logs routes
  resources :job_logs, only: [:index, :show]
  
  # OpenOrder routes
  resources :open_orders, only: [:index, :show]
  
  # Mission Control
  mount MissionControl::Jobs::Engine, at: "/jobs"
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
```

### 7. Create Views

**`app/views/job_logs/index.html.erb`**:

```erb
<div class="px-4 sm:px-6 lg:px-8">
  <!-- Header with navigation -->
  <div class="sm:flex sm:items-center sm:justify-between mb-8">
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Job Execution Logs</h1>
      <p class="mt-2 text-sm text-gray-700">Monitor background job execution history and status</p>
    </div>
    
    <!-- Navigation buttons -->
    <div class="mt-4 sm:mt-0 flex gap-2">
      <%= link_to open_orders_path, 
          class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50" do %>
        <svg class="mr-2 h-5 w-5 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Open Orders
      <% end %>
      
      <%= link_to "/jobs", 
          class: "inline-flex items-center px-4 py-2 border border-blue-300 rounded-md shadow-sm text-sm font-medium text-blue-700 bg-blue-50 hover:bg-blue-100" do %>
        <svg class="mr-2 h-5 w-5 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
        Jobs Monitor
      <% end %>
    </div>
  </div>

  <% if @job_logs.any? %>
    <!-- Logs table -->
    <div class="mt-8 flow-root">
      <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg">
            <table class="min-w-full divide-y divide-gray-300">
              <thead class="bg-gray-50">
                <tr>
                  <th class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Execution Time</th>
                  <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Status</th>
                  <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Duration</th>
                  <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Details</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 bg-white">
                <% @job_logs.each do |log| %>
                  <tr class="hover:bg-gray-50">
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                      <%= log.name %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm">
                      <% case log.status %>
                      <% when "success" %>
                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-green-100 text-green-800">✓ Success</span>
                      <% when "error" %>
                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-red-100 text-red-800">✗ Error</span>
                      <% when "processing" %>
                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-yellow-100 text-yellow-800">⟳ Processing</span>
                      <% when "new" %>
                        <span class="inline-flex rounded-full px-2 py-1 text-xs font-semibold bg-gray-100 text-gray-800">◷ New</span>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      <%= distance_of_time_in_words(log.created_at, log.updated_at) %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm">
                      <%= link_to "View Details →", job_log_path(log), class: "text-blue-600 hover:text-blue-900" %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div class="mt-4">
      <%= paginate @job_logs, theme: 'tailwind' %>
    </div>

  <% else %>
    <!-- Empty state -->
    <div class="text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">No job logs yet</h3>
      <p class="mt-1 text-sm text-gray-500">Job execution logs will appear here once jobs start running.</p>
    </div>
  <% end %>
</div>
```

**`app/views/job_logs/show.html.erb`**:

```erb
<div class="px-4 sm:px-6 lg:px-8">
  <!-- Header -->
  <div class="mb-8">
    <%= link_to "← Back to Logs", root_path, class: "text-sm text-blue-600 hover:text-blue-900" %>
    
    <div class="mt-4 sm:flex sm:items-center sm:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Job Execution: <%= @job_log.name %></h1>
        <p class="mt-2 text-sm text-gray-700">
          Started: <%= @job_log.created_at.strftime("%B %d, %Y at %I:%M:%S %p") %>
        </p>
      </div>
      
      <div class="mt-4 sm:mt-0">
        <% case @job_log.status %>
        <% when "success" %>
          <span class="inline-flex rounded-full px-4 py-2 text-sm font-semibold bg-green-100 text-green-800">✓ Success</span>
        <% when "error" %>
          <span class="inline-flex rounded-full px-4 py-2 text-sm font-semibold bg-red-100 text-red-800">✗ Error</span>
        <% when "processing" %>
          <span class="inline-flex rounded-full px-4 py-2 text-sm font-semibold bg-yellow-100 text-yellow-800">⟳ Processing</span>
        <% when "new" %>
          <span class="inline-flex rounded-full px-4 py-2 text-sm font-semibold bg-gray-100 text-gray-800">◷ New</span>
        <% end %>
      </div>
    </div>
  </div>

  <!-- Log details -->
  <% if @job_log_details.any? %>
    <div class="bg-gray-900 rounded-lg p-6 font-mono text-sm text-gray-100">
      <% @job_log_details.each do |detail| %>
        <div class="mb-2">
          <span class="text-gray-400"><%= detail.created_at.strftime("%H:%M:%S.%L") %></span>
          <span class="ml-4"><%= detail.message %></span>
        </div>
      <% end %>
    </div>
  <% else %>
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">No log details recorded yet.</p>
    </div>
  <% end %>
  
  <!-- Summary -->
  <div class="mt-8 bg-white rounded-lg shadow p-6">
    <h2 class="text-lg font-semibold text-gray-900 mb-4">Execution Summary</h2>
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-3">
      <div>
        <dt class="text-sm font-medium text-gray-500">Started At</dt>
        <dd class="mt-1 text-sm text-gray-900"><%= @job_log.created_at.strftime("%I:%M:%S %p") %></dd>
      </div>
      <div>
        <dt class="text-sm font-medium text-gray-500">Completed At</dt>
        <dd class="mt-1 text-sm text-gray-900"><%= @job_log.updated_at.strftime("%I:%M:%S %p") %></dd>
      </div>
      <div>
        <dt class="text-sm font-medium text-gray-500">Duration</dt>
        <dd class="mt-1 text-sm text-gray-900"><%= distance_of_time_in_words(@job_log.created_at, @job_log.updated_at) %></dd>
      </div>
    </dl>
  </div>
</div>
```

### 8. Update SyncOpenOrdersJob

**`app/jobs/sync_open_orders_job.rb`** - Add logging integration:

```ruby
class SyncOpenOrdersJob < ApplicationJob
  queue_as :default

  def perform
    # Create job log
    job_log = JobLog.create_with_timestamp!
    job_log.add_detail("Job started - SyncOpenOrdersJob")
    
    # Update to processing
    job_log.processing!
    
    start_time = Time.current
    
    # Connect to SQL Server
    job_log.add_detail("Connecting to SQL Server #{SqlServerConnector::HOST}...")
    connector = SqlServerConnector.new
    job_log.add_detail("Connected successfully")
    
    # Fetch data
    job_log.add_detail("Fetching records from vwZSDOrder_Advanced...")
    query = "SELECT * FROM vwZSDOrder_Advanced"
    result = connector.execute(query)
    
    records = result.to_a
    job_log.add_detail("Fetched #{records.length} records")
    
    # Import data
    job_log.add_detail("Truncating existing open_orders table...")
    importer = OpenOrdersImporter.new
    imported_count = importer.import(records, job_log)
    
    # Complete
    duration = (Time.current - start_time).round
    job_log.add_detail("Job completed successfully - Total: #{imported_count} records in #{duration} seconds")
    job_log.success!
    
    Rails.logger.info("SyncOpenOrdersJob completed: #{imported_count} records in #{duration}s")
    
  rescue SqlServerConnector::ConnectionError, SqlServerConnector::QueryError => e
    error_msg = "SQL Server error: #{e.message}"
    job_log&.add_detail("ERROR: #{error_msg}")
    job_log&.error!
    Rails.logger.error("SyncOpenOrdersJob failed: #{error_msg}")
    raise
    
  rescue OpenOrdersImporter::ImportError => e
    error_msg = "Import error: #{e.message}"
    job_log&.add_detail("ERROR: #{error_msg}")
    job_log&.error!
    Rails.logger.error("SyncOpenOrdersJob failed: #{error_msg}")
    raise
    
  rescue => e
    error_msg = "Unexpected error: #{e.class} - #{e.message}"
    job_log&.add_detail("ERROR: #{error_msg}")
    job_log&.error!
    Rails.logger.error("SyncOpenOrdersJob failed: #{error_msg}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
    
  ensure
    connector&.close
  end
end
```

**Update `app/services/open_orders_importer.rb`** - Add job_log parameter:

```ruby
def import(sql_rows, job_log = nil)
  return 0 if sql_rows.empty?
  
  job_log&.add_detail("Importing records in batches of #{BATCH_SIZE}...")
  
  OpenOrder.transaction do
    OpenOrder.delete_all
    
    sql_rows.each_slice(BATCH_SIZE).with_index(1) do |batch, batch_num|
      rails_records = batch.map { |row| map_row(row) }
      OpenOrder.insert_all(rails_records)
      
      total_batches = (sql_rows.length.to_f / BATCH_SIZE).ceil
      job_log&.add_detail("Batch #{batch_num}/#{total_batches} imported (#{batch.length} records)")
    end
  end
  
  sql_rows.length
rescue => e
  raise ImportError, "Failed to import records: #{e.message}"
end
```

### 9. Remove Jobs Monitor Button from Open Orders

**`app/views/open_orders/index.html.erb`** - Remove the Jobs Monitor button (it's now on JobLogs index):

```erb
<!-- Remove this button -->
<%#= link_to "/jobs", class: "..." do %>
  <!-- Jobs Monitor button content -->
<%# end %>
```

## Testing Steps

### 1. Manual Job Trigger Test

```bash
# Trigger sync job manually
bin/rails sync:open_orders
```

**Expected Result**:
- New JobLog created with timestamp name
- Status transitions: new → processing → success
- Multiple JobLogDetail messages captured
- Navigate to root page (http://localhost:3000) and verify log appears

### 2. View Job Log Details

1. Visit root page: http://localhost:3000
2. Click on any job log entry
3. Verify detailed log messages display chronologically
4. Verify status badge matches log status
5. Verify execution summary shows correct times/duration

### 3. Recurring Job Test

```bash
# Start Rails and job worker
bin/dev
```

**Expected Result**:
- New JobLog created every 5 minutes
- Each has unique timestamp name
- All appear on index page sorted by most recent first

### 4. Error Scenario Test

```bash
# Temporarily break SQL Server connection (e.g., wrong password in credentials)
# Trigger job
bin/rails sync:open_orders
```

**Expected Result**:
- JobLog created with status "error"
- Error message captured in JobLogDetail
- Red error badge displays on index page

### 5. Navigation Test

1. Visit root: http://localhost:3000 → Should show JobLogs index
2. Click "Open Orders" → Should navigate to open_orders#index
3. Click "Jobs Monitor" from JobLogs index → Should open Mission Control

### 6. Collision Test

```bash
# In Rails console
irb(main)> JobLog.create_with_timestamp!(Time.current)
irb(main)> JobLog.create_with_timestamp!(Time.current)  # Same second
```

**Expected Result**:
- First log: name = "YYYYMMDDhhmmss"
- Second log: name = "YYYYMMDDhhmmss_1"

## Troubleshooting

### Issue: "Table 'job_logs' doesn't exist"

```bash
# Solution: Run migrations
bin/rails db:migrate
```

### Issue: Authentication required for JobLogsController

```bash
# Solution: Set environment variables or use defaults
export ADMIN_USERNAME=admin
export ADMIN_PASSWORD=password
```

### Issue: JobLog not created when job runs

**Check**:
1. Verify models have correct associations
2. Check job code includes `JobLog.create_with_timestamp!`
3. Verify database migrations ran successfully

### Issue: Pagination not working

```bash
# Solution: Ensure Kaminari is in Gemfile
# Add to Gemfile if missing:
gem "kaminari"

# Then run:
bundle install
```

## Next Steps

1. Monitor first 24 hours of logs (288 expected entries at 5-minute intervals)
2. Verify log details provide sufficient troubleshooting information
3. Test error recovery (ensure jobs can retry after failures)
4. Consider adding log retention policy (archive/delete old logs after 90 days)

## Summary

The Job Execution Logging feature is now fully implemented and operational. The root page displays job history, detailed logs are viewable for each execution, and automatic logging captures all job activity. Navigation between JobLogs, Open Orders, and Mission Control is seamless.
