# platform01_inside_worker Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-14

## Active Technologies

- Ruby 3.3.5 / Rails 8.1.1 (per constitution) (002-sqlserver-sync-worker)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Ruby 3.3.5 / Rails 8.1.1 (per constitution)

## Code Style

Ruby 3.3.5 / Rails 8.1.1 (per constitution): Follow standard conventions

## Recent Changes

- 002-sqlserver-sync-worker: Added Ruby 3.3.5 / Rails 8.1.1 (per constitution)

<!-- MANUAL ADDITIONS START -->

## SQL Server Integration (TinyTDS)

### Connection Pattern

```ruby
# Service object pattern for SQL Server connections
class SqlServerConnector
  def initialize
    config = Rails.configuration.database_configuration['sqlserver']
    @client = TinyTds::Client.new(
      host: config['host'],
      username: config['username'],
      password: config['password'],
      database: config['database'],
      timeout: config['timeout'] || 30
    )
  end

  def execute(query)
    result = @client.execute(query)
    result.each.to_a # Convert to array
  ensure
    result&.cancel # Clean up result set
  end

  def close
    @client.close if @client
  end
end
```

### Column Mapping Pattern

```ruby
# Explicit hash-based mapping (fail-fast approach)
COLUMN_MAPPING = {
  'SQLServerColumn' => :rails_attribute,
  'AnotherColumn' => :another_attribute
}.freeze

# Conversion with type safety
def convert_value(rails_attr, value)
  return nil if value.blank?
  
  case rails_attr
  when :date_field
    Date.parse(value.to_s) rescue nil
  when :integer_field
    value.to_i
  else
    value.to_s.strip
  end
end
```

### Batch Import Pattern

```ruby
# Fetch first, then transactional delete + insert
def import(sql_rows)
  record_count = 0
  
  Model.transaction do
    Model.delete_all  # Only after successful fetch
    
    sql_rows.each_slice(BATCH_SIZE) do |batch|
      mapped = batch.map { |row| map_row(row) }
      Model.insert_all(mapped, returning: false)
      record_count += batch.size
    end
  end
  
  record_count
end
```

### Solid Queue Recurring Job Pattern

```ruby
# config/recurring.yml
job_name:
  class: MyJobClass
  schedule: "*/5 * * * *"  # Every 5 minutes
  queue: default

# app/jobs/my_job.rb
class MyJob < ApplicationJob
  queue_as :default
  
  def perform
    # Solid Queue prevents concurrent executions automatically
    # Just implement the work
  end
end
```

<!-- MANUAL ADDITIONS END -->
