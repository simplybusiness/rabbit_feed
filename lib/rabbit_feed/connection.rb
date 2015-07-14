module RabbitFeed
  class Connection
    include Singleton

    def initialize
      RabbitFeed.log.info {{ event: :connecting_to_rabbitmq, options: RabbitFeed.configuration.connection_options.merge({password: :redacted, logger: :redacted}) }}
      @connection = Bunny.new RabbitFeed.configuration.connection_options
      @connection.start
      RabbitFeed.log.info {{ event: :connected_to_rabbitmq }}
      @channel = @connection.create_channel
      @mutex = Mutex.new
    end

    private

    attr_reader :channel, :mutex

    def synchronized &block
      mutex.synchronize do
        yield
      end
    end

    def connection_in_use?
      mutex.locked?
    end
  end
end
