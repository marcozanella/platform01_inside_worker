# Service object for connecting to SQL Server and executing queries
# Uses TinyTDS gem with FreeTDS for SQL Server connectivity
class SqlServerConnector
  class ConnectionError < StandardError; end
  class QueryError < StandardError; end

  def initialize
    @config = Rails.configuration.database_configuration['sqlserver']
    @client = nil
  end

  # Execute a SQL query and return results as array of hashes
  def execute(query)
    ensure_connected
    
    Rails.logger.info "[SqlServerConnector] Executing query: #{sanitize_query(query)}"
    result = @client.execute(query)
    rows = result.each.to_a
    Rails.logger.info "[SqlServerConnector] Query returned #{rows.size} rows"
    
    rows
  rescue TinyTds::Error => e
    Rails.logger.error "[SqlServerConnector] Query error: #{e.message}"
    raise QueryError, "SQL Server query failed: #{e.message}"
  ensure
    result&.cancel # Clean up result set
  end

  # Close the connection
  def close
    if @client
      @client.close
      @client = nil
      Rails.logger.info "[SqlServerConnector] Connection closed"
    end
  end

  # Check if connection is active
  def connected?
    @client&.active? || false
  end

  private

  def ensure_connected
    return if connected?
    
    connect
  end

  def connect
    Rails.logger.info "[SqlServerConnector] Connecting to SQL Server: #{@config['host']}/#{@config['database']}"
    
    @client = TinyTds::Client.new(
      host: @config['host'],
      username: @config['username'],
      password: @config['password'],
      database: @config['database'],
      timeout: @config['timeout'] || 30,
      encoding: @config['encoding'] || 'utf8'
    )
    
    unless @client.active?
      raise ConnectionError, "Failed to establish connection to SQL Server"
    end
    
    Rails.logger.info "[SqlServerConnector] Connection established successfully"
  rescue TinyTds::Error => e
    # Mask password in error messages
    error_msg = e.message.gsub(@config['password'], '***')
    Rails.logger.error "[SqlServerConnector] Connection failed: #{error_msg}"
    raise ConnectionError, "SQL Server connection failed: #{error_msg}"
  end

  def sanitize_query(query)
    # Remove sensitive data from logged queries
    query.gsub(@config['password'], '***') if @config['password']
  end
end
