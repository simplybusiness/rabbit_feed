module RabbitFeed
  class Connection

    attr_reader :connection, :configuration

    def self.open &block
      connection_pool.with do |connection|
        connection.reset unless connection.open?
        yield connection
      end
    end

    def self.reconnect!
      RabbitFeed.log.debug 'Reconnecting...'
      @connection_pool.shutdown{|connection| connection.close } unless @connection_pool.nil?
      @connection_pool = nil
    end

    def initialize configuration
      @configuration = configuration
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
      RabbitFeed.log.debug 'Closing connection...'

      connection.close unless connection.nil?
    rescue => e
      RabbitFeed.log.warn "Exception encountered whilst closing: #{e.message} #{e.backtrace}"
    end

    private

    def self.connection_pool
      @configuration   ||= Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment
      @connection_pool ||= ConnectionPool.new(
        size:    @configuration.pool_size,
        timeout: @configuration.pool_timeout
      ) do
        new @configuration
      end
    end

    def open
      RabbitFeed.log.debug 'Opening connection...'

      tries = 3
      begin
        connection = Bunny.new({
                heartbeat:       configuration.heartbeat,
                connect_timeout: configuration.connect_timeout,
                host:            configuration.host,
                user:            configuration.user,
                password:        configuration.password,
                port:            configuration.port,
              })
        connection.start
        connection
      rescue => e
        RabbitFeed.log.warn "Exception encountered whilst opening on try ##{4-tries}: #{e.message} #{e.backtrace}"
        retry unless (tries -= 1).zero?
        raise
      end
    end
  end
end
