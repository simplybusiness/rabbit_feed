module RabbitFeed
  module TestingSupport
    class TestRabbitFeedConsumer
      def consume_event name, application, payload, version='n/a'
        publishing_options = PublishingOptions.new name, Time.now.utc, version
        event = Event.new 'no schema', payload, publishing_options.metadata.merge({'application' => application})
        RabbitFeed::Consumer.event_routing.handle_event event
      end
    end
  end
end
