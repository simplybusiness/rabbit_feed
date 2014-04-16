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

    def close
      connection.close unless connection.nil?
    rescue
    end

    def open
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
    end
  end
end
