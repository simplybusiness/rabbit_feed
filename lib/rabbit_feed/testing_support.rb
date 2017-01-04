require 'rabbit_feed/testing_support/test_rabbit_feed_consumer'
require 'rabbit_feed/testing_support/testing_helpers'

module RabbitFeed
  module TestingSupport
    extend self

    attr_accessor :published_events

    def setup(rspec_config)
      require 'rabbit_feed/testing_support/rspec_matchers/publish_event'
      RabbitFeed.environment ||= 'test'
      capture_published_events rspec_config
      include_support rspec_config
    end

    def capture_published_events(rspec_config)
      rspec_config.before :each do
        TestingSupport.capture_published_events_in_context(self)
      end
    end

    def capture_published_events_in_context(context)
      TestingSupport.published_events = []
      mock_connection = context.double(:rabbitmq_connection)
      context.allow(RabbitFeed::ProducerConnection).to context.receive(:instance).and_return(mock_connection)
      context.allow(mock_connection).to context.receive(:publish) do |serialized_event, _routing_key|
        TestingSupport.published_events << (Event.deserialize serialized_event)
      end
    end

    def include_support(rspec_config)
      rspec_config.include(RabbitFeed::TestingSupport::TestingHelpers)
    end
  end
end
