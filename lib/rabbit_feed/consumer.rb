module RabbitFeed
  module Consumer
    extend self

    attr_accessor :event_routing

    def run
      ConsumerConnection.consume do |raw_event|
        event = Event.deserialize raw_event
        event_routing.handle_event event
      end
    end
  end
end
