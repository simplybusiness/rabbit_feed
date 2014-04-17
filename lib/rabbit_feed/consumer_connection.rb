module RabbitFeed
  class ConsumerConnection < Connection

    SUBSCRIPTION_OPTIONS = {
      consumer_tag: ::Socket.gethostname, # Use the host name of the server
      ack:          true, # Manually acknowledge messages once they've been processed
      block:        true, # Block the thread whilst consuming from the queue
    }.freeze

    def self.consume &block
      open do |connection|
        connection.consume(&block)
      end
    end

    def consume &block
      queue.channel.prefetch(1) # Fetch one message at a time to preserve order
      queue.subscribe(SUBSCRIPTION_OPTIONS) do |delivery_info, properties, payload|
        yield payload
        queue.channel.ack(delivery_info.delivery_tag)
      end
    end

    def initialize configuration
      super
      queue.bind(configuration.exchange)
    end

    private

    QUEUE_OPTIONS = {
      durable:    true,
      no_declare: false,
      arguments:  {'x-ha-policy' => 'all'},
    }.freeze

    def queue
      @connection.queue configuration.queue, QUEUE_OPTIONS
    end
  end
end
