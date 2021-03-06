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

    def self.handle_returned_message(return_info, _content)
      RabbitFeed.log.error { { event: :returned_message, return_info: return_info } }
      RabbitFeed.exception_notify(ReturnedMessageError.new(return_info))
    end

    def initialize
      super
      @exchange = channel.exchange RabbitFeed.configuration.exchange, exchange_options
      RabbitFeed.log.info { { event: :exchange_declared, exchange: RabbitFeed.configuration.exchange, options: exchange_options } }
      exchange.on_return do |return_info, _properties, content|
        RabbitFeed::ProducerConnection.handle_returned_message return_info, content
      end
    end

    def publish(message, options)
      synchronized do
        bunny_options = (options.merge PUBLISH_OPTIONS)
        RabbitFeed.log.debug { { event: :publish, options: options, exchange: RabbitFeed.configuration.exchange } }
        exchange.publish message, bunny_options
      end
    end

    private

    attr_reader :exchange

    def exchange_options
      {
        auto_delete: RabbitFeed.configuration.auto_delete_exchange
      }.merge EXCHANGE_OPTIONS
    end
  end
end
