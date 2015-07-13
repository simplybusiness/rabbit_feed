module RabbitFeed
  class ConsumerConnection < RabbitFeed::Connection

    SUBSCRIPTION_OPTIONS = {
      consumer_tag: Socket.gethostname, # Use the host name of the server
      manual_ack:   true, # Manually acknowledge messages once they've been processed
      block:        false, # Don't block the thread whilst consuming from the queue, as this breaks during connection recovery
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

    def initialize
      super
      channel.prefetch(1)
      @queue = channel.queue RabbitFeed.configuration.queue, queue_options
      bind_on_accepted_routes
    end

    def consume &block
      raise 'This connection already has a consumer subscribed' if mutex.locked?
      synchronized do
        begin
          RabbitFeed.log.info "Consuming messages on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."

          consumer = queue.subscribe(SUBSCRIPTION_OPTIONS) do |delivery_info, properties, payload|
            handle_message delivery_info, payload, &block
          end

          sleep # Sleep indefinitely, as the consumer runs in its own thread
        rescue SystemExit, Interrupt
          RabbitFeed.log.info "Consumer #{self.to_s} received exit request, exiting..."
        ensure
          (cancel_consumer consumer) if consumer.present?
        end
      end
    end

    private

    attr_reader :queue

    def queue_options
      {
        auto_delete: RabbitFeed.configuration.auto_delete_queue,
      }.merge QUEUE_OPTIONS
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

    def acknowledge delivery_info
      queue.channel.ack(delivery_info.delivery_tag)
      RabbitFeed.log.debug "Message acknowledged on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."
    end

    def handle_message delivery_info, payload, &block
      RabbitFeed.log.debug "Message received on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."

      begin
        yield payload
        acknowledge delivery_info
      rescue => e
        handle_processing_exception delivery_info, e
      end
    end

    def cancel_consumer consumer
      cancel_ok = consumer.cancel
      RabbitFeed.log.debug "Consumer: #{cancel_ok.consumer_tag} cancelled on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."
    end

    def negative_acknowledge delivery_info
      # Tell rabbit that we were unable to process the message
      # This will re-queue the message
      queue.channel.nack(delivery_info.delivery_tag, false, true)
      RabbitFeed.log.debug "Message negatively acknowledged on #{self.to_s} from queue: #{RabbitFeed.configuration.queue}..."
    end

    def handle_processing_exception delivery_info, exception
      negative_acknowledge delivery_info
      RabbitFeed.log.error "Exception encountered while consuming message on #{self.to_s} from queue #{RabbitFeed.configuration.queue}: #{exception.message} #{exception.backtrace}"
      RabbitFeed.exception_notify exception
    end
  end
end
