module RabbitFeed
  class Consumer

    def start
      ConsumerConnection.consume do |raw_event|
        event = Event.deserialize raw_event
        RabbitFeed.event_handler_klass.constantize.new.handle_event event.name, event.payload
      end
    end
  end
end
