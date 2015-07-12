module RabbitFeed
  class Connection
    include Singleton

    def initialize
      connection.start
      @mutex = Mutex.new
    end

    protected

    def thread_safe &block
      @mutex.synchronize do
        yield
      end
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      @connection ||= Bunny.new RabbitFeed.configuration.connection_options
    end
  end
end
