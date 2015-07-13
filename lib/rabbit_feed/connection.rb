module RabbitFeed
  class Connection
    include Singleton

    def initialize
      @connection = Bunny.new RabbitFeed.configuration.connection_options
      @connection.start
      @channel = @connection.create_channel
      @mutex = Mutex.new
    end

    protected

    attr_reader :channel

    def thread_safe &block
      @mutex.synchronize do
        yield
      end
    end
  end
end
