module RabbitFeed
  class Consumer

    def self.start
      ConsumerConnection.consume do |raw_event|
        event = Event.deserialize raw_event
        event_handler.handle_event event
      end
    end

    private

    def self.event_handler
      RabbitFeed.event_handler_klass.constantize.new
    end
  end
end
