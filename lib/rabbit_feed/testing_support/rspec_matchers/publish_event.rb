require 'rspec/expectations'

module TestingSupport
  RSpec::Matchers.define :publish_event do |expected_event, expected_payload = nil|
    match do |given_proc|
      RabbitFeed::TestingSupport.published_events.clear
      given_proc.call rescue nil
      actual_event = first_matching_event(expected_event)
      if actual_event.nil?
        false
      elsif expected_payload
        actual_event.payload == expected_payload
      elsif @included_in_payload
        (@included_in_payload.to_a - actual_event.payload.to_a).empty?
      elsif @asserting_block
        @asserting_block.call(actual_event.payload)
      else
        true
      end
    end

    failure_message do |_str|
      "expected #{expected_event} with #{expected_payload || @included_in_payload || 'some payload'} but instead received #{received_events_message}"
    end

    failure_message_when_negated do |_str|
      "expected no #{expected_event} event, but received one anyways"
    end

    chain :including do |included_in_payload|
      if expected_payload
        Kernel.warn '`publish_event` was called with an expected payload already, anything in `including` is ignored'
      else
        @included_in_payload = included_in_payload
      end
    end

    chain :asserting do |&block|
      if expected_payload || @included_in_payload
        Kernel.warn '`publish_event` was called with an expected payload already, anything in `asserting` is ignored'
      else
        @asserting_block = block
      end
    end

    supports_block_expectations

    def first_matching_event(expected_event)
      RabbitFeed::TestingSupport.published_events.detect do |event|
        event.name == expected_event
      end
    end

    def received_events_message
      if RabbitFeed::TestingSupport.published_events.any?
        RabbitFeed::TestingSupport.published_events.map do |received_event|
          "#{received_event.name} with #{received_event.payload}"
        end
      else
        'no events'
      end
    end
  end
end
