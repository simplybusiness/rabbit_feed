module RabbitFeed
  class Connection

    attr_reader :connection

    def self.open &block
      connection_pool.with do |connection|
        begin
          connection.reset unless connection.open?
          yield connection
        rescue
          # If the operation failed, it was likely due to connectivity problems, so reset the connection
          connection.reset
          raise
        end
      end
    end

    def self.reconnect!
      RabbitFeed.log.debug 'Reconnecting...'
      @connection_pool.shutdown{|connection| connection.close } unless @connection_pool.nil?
      @connection_pool = nil
    end

    def initialize
      reset
    end

    def reset
      close
      @connection = open
    end

    def open?
      connection.open? unless connection.nil?
    end

    def close
      RabbitFeed.log.debug "Closing connection: #{self.to_s}..."

      connection.close unless connection.nil?
    rescue => e
      RabbitFeed.log.warn "Exception encountered whilst closing #{self.to_s}: #{e.message} #{e.backtrace}"
    end

    private

    def self.retry_on_exception tries=3, &block
      yield
    rescue => e
      RabbitFeed.log.warn "Exception encountered; #{tries - 1} tries remaining. #{self.to_s}: #{e.message} #{e.backtrace}"
      retry unless (tries -= 1).zero?
      raise
    end

    def self.connection_pool
      @connection_pool ||= ConnectionPool.new(
        size:    RabbitFeed.configuration.pool_size,
        timeout: RabbitFeed.configuration.pool_timeout
      ) do
        new
      end
    end

    def open
      RabbitFeed.log.debug "Opening connection: #{self.to_s}..."

      Connection.retry_on_exception do
        connection = Bunny.new({
                heartbeat:       RabbitFeed.configuration.heartbeat,
                connect_timeout: RabbitFeed.configuration.connect_timeout,
                host:            RabbitFeed.configuration.host,
                user:            RabbitFeed.configuration.user,
                password:        RabbitFeed.configuration.password,
                port:            RabbitFeed.configuration.port,
                logger:          RabbitFeed.log,
              })
        connection.start
        connection
      end
    end
  end
end
