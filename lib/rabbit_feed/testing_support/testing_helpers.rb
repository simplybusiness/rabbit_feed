module RabbitFeed
  module TestingSupport
    module TestingHelpers

      def rabbit_feed_consumer
        TestRabbitFeedConsumer.new
      end
    end
  end
end
