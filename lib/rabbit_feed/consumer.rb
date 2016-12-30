module RabbitFeed
  module Consumer
    extend self

    attr_accessor :event_routing

    def run
      ConsumerConnection.instance.consume do |raw_event|
        event = Event.deserialize raw_event
        RabbitFeed.log.info { { event: :message_received, metadata: event.metadata } }
        event_routing.handle_event event
        RabbitFeed.log.info { { event: :message_processed, metadata: event.metadata } }
      end
    end
  end
end
