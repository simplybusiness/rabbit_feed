module RabbitFeed
  module Consumer
    extend self

    attr_accessor :event_routing

    def run
      begin
        start
      rescue ConfigurationError
        raise
      rescue => e
        RabbitFeed.log.error "Error while consuming: #{e.message} #{e.backtrace}"
        RabbitFeed.exception_notify e
        RabbitFeed::ConsumerConnection.reconnect!
      end while recover?
    end

    def start
      ConsumerConnection.consume do |raw_event|
        event = Event.deserialize raw_event
        event_routing.handle_event event
      end
    end

    def recover?
      true
    end
  end
end
