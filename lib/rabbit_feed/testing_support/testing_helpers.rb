module RabbitFeed
  module TestingSupport
    module TestingHelpers
      def rabbit_feed_consumer
        TestRabbitFeedConsumer.new
      end
    end

    class TestRabbitFeedConsumer
      def consume_event(event)
        event = Event.new('no schema',event)
        RabbitFeed::Consumer.event_routing.handle_event(event)
      end
    end
  end
end
