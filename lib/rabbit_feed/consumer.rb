module RabbitFeed
  module Consumer
    extend self

    attr_accessor :event_routing

    def run
      ConsumerConnection.consume do |payload, metadata|
        event = Event.deserialize payload, metadata
        event_routing.handle_event event
      end
    end
  end
end
