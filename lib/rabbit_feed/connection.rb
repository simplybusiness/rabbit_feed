module RabbitFeed
  class Connection
    include Singleton

    def initialize
      @connection = Bunny.new RabbitFeed.configuration.connection_options
      @connection.start
      @channel = @connection.create_channel
      @mutex = Mutex.new
    end

    private

    attr_reader :channel

    def synchronized &block
      @mutex.synchronize do
        yield
      end
    end
  end
end
