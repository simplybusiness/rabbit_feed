module RabbitFeed
  module TestingSupport
    class TestRabbitFeedConsumer
      def consume_event(event)
        event = Event.new('no schema',event)
        RabbitFeed::Consumer.event_routing.handle_event(event)
      end
    end
  end
end
