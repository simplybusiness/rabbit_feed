require 'spec_helper'

step 'I am consuming' do
  set_event_routing
  set_event_definitions
  RabbitFeed::ConsumerConnection.instance # Bind the queue
  @consumer_thread = Thread.new { RabbitFeed::Consumer.run }
end

step 'I publish an event' do
  publish 'test'
end

step 'I receive that event' do
  event = wait_for_event
  assert_event_presence event
end

step 'I publish an event that cannot be processed by the consumer' do
  publish 'test_failure'
end

step 'the event remains on the queue' do
  event = nil
  2.times { event = wait_for_event }
  assert_event_presence event
end

module Turnip::Steps
  def publish(event_name)
    @event_text = "#{event_name}_#{Time.now.iso8601(6)}"
    RabbitFeed::Producer.publish_event event_name, 'field' => @event_text
  end

  def assert_event_presence(event)
    expect(event).to_not be_nil
    expect(event.payload[:field]).to eq @event_text
  end

  def wait_for_event
    begin
      Timeout.timeout(2.0) do
        sleep 0.1 until @consumed_events.any?
      end
    rescue Timeout::Error
    end
    @consumed_events.pop
  end

  def set_event_definitions
    EventDefinitions do
      define_event('test', version: '1.0.0') do
        defined_as do
          'The test event'
        end
        payload_contains do
          field('field', type: 'string', definition: 'The field')
        end
      end
      define_event('test_failure', version: '1.0.0') do
        defined_as do
          'The test failure event'
        end
        payload_contains do
          field('field', type: 'string', definition: 'The field')
        end
      end
    end
  end

  def set_event_routing
    consumed_events  = []
    @consumed_events = consumed_events

    EventRouting do
      accept_from('rabbit_feed') do
        event('test') do |event|
          consumed_events << event
        end
        event('test_failure') do |event|
          consumed_events << event
          raise 'event processing failure'
        end
      end
    end
  end
end
