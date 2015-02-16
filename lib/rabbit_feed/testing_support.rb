require 'rabbit_feed/testing_support/rspec_matchers/publish_event'
require 'rabbit_feed/testing_support/test_rabbit_feed_consumer'
require 'rabbit_feed/testing_support/testing_helpers'

module RabbitFeed
  module TestingSupport
    extend self

    attr_accessor :published_events

    def setup rspec_config
      capture_published_events rspec_config
      include_support rspec_config
    end

    def capture_published_events rspec_config
      rspec_config.before :each do

        TestingSupport.published_events = []

        allow(RabbitFeed::ProducerConnection).to receive(:publish) do |serialized_event, options|
          TestingSupport.published_events << (Event.deserialize serialized_event, options[:headers])
        end
      end
    end

    def include_support rspec_config
      rspec_config.include(RabbitFeed::TestingSupport::RSpecMatchers)
      rspec_config.include(RabbitFeed::TestingSupport::TestingHelpers)
    end
  end
end
