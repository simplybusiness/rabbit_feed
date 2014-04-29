module RabbitFeed
  class Consumer

    def self.start
      ConsumerConnection.consume do |raw_event|
        event = Event.deserialize raw_event
        RabbitFeed.event_routing.handle_event event
      end
    end
  end
end
