module RabbitFeed
  class ProducerConnection
    include Connection

    PUBLISH_OPTIONS = {
      persistent: true, # Persist the message to disk
      mandatory:  true, # Return the message if it can't be routed to a queue
    }.freeze

    EXCHANGE_OPTIONS = {
      type:        :topic, # Allow wildcard routing keys
      durable:     true,   # Persist across server restart
      no_declare:  false,  # Create the exchange if it does not exist
    }.freeze

    attr_reader :exchange

    def initialize channel
      exchange_options = {
        auto_delete: RabbitFeed.configuration.auto_delete_exchange,
      }
      @exchange = channel.exchange RabbitFeed.configuration.exchange, (exchange_options.merge EXCHANGE_OPTIONS)

      exchange.on_return do |return_info, properties, content|
        RabbitFeed::ProducerConnection.handle_returned_message return_info, content
      end
    end

    def self.publish message, options, tries = 3
      retry_on_closed_connection do
        open do |producer_connection|
          retry_on_exception do
            producer_connection.publish message, options
          end
        end
      end
    end

    def publish message, options, tries = 3
      # It's critical to dup the options for the sake of retries, as bunny modifies this hash
      bunny_options = (options.merge PUBLISH_OPTIONS)

      RabbitFeed.log.debug "Publishing message on #{self.to_s} with options: #{options} to exchange: #{RabbitFeed.configuration.exchange}..."

      exchange.publish message, bunny_options
    end

    def self.handle_returned_message return_info, content
      RabbitFeed.log.error "Handling returned message on #{self.to_s} details: #{return_info}..."
      RabbitFeed.exception_notify (ReturnedMessageError.new return_info)
    end

    private

    def self.connection_options
      default_connection_options.merge({
        threaded: false,
      })
    end
  end
end
