module RabbitFeed
  module TestingSupport
    class TestRabbitFeedConsumer

      def consume_event event
        RabbitFeed::Consumer.event_routing.handle_event event
      end
    end
  end
end
