module RabbitFeed
  class ProducerConnection < RabbitFeed::Connection

    PUBLISH_OPTIONS = {
      persistent: true, # Persist the message to disk
      mandatory:  true, # Return the message if it can't be routed to a queue
    }.freeze

    EXCHANGE_OPTIONS = {
      type:        :topic, # Allow wildcard routing keys
      durable:     true,   # Persist across server restart
      no_declare:  false,  # Create the exchange if it does not exist
    }.freeze

    def self.handle_returned_message return_info, content
      RabbitFeed.log.error "Handling returned message on #{self.to_s} details: #{return_info}..."
      RabbitFeed.exception_notify (ReturnedMessageError.new return_info)
    end

    def initialize
      super
      exchange.on_return do |return_info, properties, content|
        RabbitFeed::ProducerConnection.handle_returned_message return_info, content
      end
    end

    def publish message, options
      thread_safe do
        bunny_options = (options.merge PUBLISH_OPTIONS)

        RabbitFeed.log.debug "Publishing message on #{self.to_s} with options: #{options} to exchange: #{RabbitFeed.configuration.exchange}..."

        exchange.publish message, bunny_options
      end
    end

    private

    def exchange_options
      {
        auto_delete: RabbitFeed.configuration.auto_delete_exchange,
      }.merge EXCHANGE_OPTIONS
    end

    def exchange
      @exchange ||= channel.exchange RabbitFeed.configuration.exchange, exchange_options
    end
  end
end
