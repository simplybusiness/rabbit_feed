module RabbitFeed
  class ConsumerConnection
    include Connection

    SUBSCRIPTION_OPTIONS = {
      consumer_tag: Socket.gethostname, # Use the host name of the server
      ack:          true, # Manually acknowledge messages once they've been processed
      block:        false, # Don't block the thread whilst consuming from the queue, as this leads to some strange threading issues
    }.freeze

    SEVEN_DAYS_IN_MS = 7.days * 1000

    QUEUE_OPTIONS = {
      durable:     true,  # Persist across server restart
      no_declare:  false, # Create the queue if it does not exist
      arguments:   {
        'x-ha-policy' => 'all', # Apply the queue on all mirrors
        'x-expires'   => SEVEN_DAYS_IN_MS, # Auto-delete the queue after a period of inactivity (in ms)
        },
    }.freeze

    attr_reader :queue

    def initialize channel
      channel.prefetch(1) # Fetch one message at a time to preserve order
      queue_options = {
        auto_delete: RabbitFeed.configuration.auto_delete_queue,
      }
      @queue = channel.queue RabbitFeed.configuration.queue, (queue_options.merge QUEUE_OPTIONS)
      bind_on_accepted_routes
    end

    def self.consume &block
      open do |consumer_connection|
        consumer_connection.consume(&block)
      end
    end

    def consume &block
      RabbitFeed.log.info "Consuming messages on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."

      consumer = queue.subscribe(SUBSCRIPTION_OPTIONS) do |delivery_info, properties, payload|
        RabbitFeed.log.debug "Message received on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."

        begin
          yield payload
        rescue => e
          handle_processing_exception delivery_info, e
        end
        queue.channel.ack(delivery_info.delivery_tag)

        RabbitFeed.log.debug "Message acknowledged on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."
      end

      sleep
    rescue
      cancel_ok = consumer.cancel
      RabbitFeed.log.debug "Consumer: #{cancel_ok.consumer_tag} cancelled on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."
      raise
    end

    private

    def self.connection_options
      default_connection_options.merge({
        threaded: true,
      })
    end

    def bind_on_accepted_routes
      if RabbitFeed::Consumer.event_routing.present?
        RabbitFeed::Consumer.event_routing.accepted_routes.each do |accepted_route|
          queue.bind(RabbitFeed.configuration.exchange, { routing_key: accepted_route })
        end
      else
        queue.bind(RabbitFeed.configuration.exchange)
      end
    end

    def handle_processing_exception delivery_info, exception
      # Tell rabbit that we were unable to process the message
      # This will re-queue the message
      queue.channel.nack(delivery_info.delivery_tag, false, true)
      RabbitFeed.log.debug "Message negatively acknowledged on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."

      RabbitFeed.log.error "Exception encountered while consuming message on #{self.to_s} from queue #{RabbitFeed.configuration.queue}: #{exception.message} #{exception.backtrace}"
      RabbitFeed.exception_notify exception
    end
  end
end
