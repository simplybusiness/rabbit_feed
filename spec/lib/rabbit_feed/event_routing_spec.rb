require 'spec_helper'

module RabbitFeed
  describe EventRouting do
    before do
      EventRouting do
        accept_from(application: 'dummy_1', version: '1.0.0') do
          event('event_1') do |event|
            event.payload
          end
          event('event_2') do |event|
            event.payload
          end
        end
        accept_from(application: 'dummy_1', version: '2.0.0') do
          event('event_3') do |event|
            event.payload
          end
          event('event_4') do |event|
            event.payload
          end
        end
        accept_from(application: 'dummy_2', version: '2.0.0') do
          event('event_5') do |event|
            event.payload
          end
        end
      end
    end

    it 'should create routing keys for the specified routes' do

      RabbitFeed.event_routing.accepted_routes.should =~ %w{
        test.dummy_1.1.0.0.event_1
        test.dummy_1.1.0.0.event_2
        test.dummy_1.2.0.0.event_3
        test.dummy_1.2.0.0.event_4
        test.dummy_2.2.0.0.event_5
      }
    end

    it 'routes the event to the correct action' do
      events = [
        (Event.new 'dummy_1', '1.0.0', 'event_1', 1),
        (Event.new 'dummy_1', '1.0.0', 'event_2', 2),
        (Event.new 'dummy_1', '2.0.0', 'event_3', 3),
        (Event.new 'dummy_1', '2.0.0', 'event_4', 4),
        (Event.new 'dummy_2', '2.0.0', 'event_5', 5),
      ]
      events.each do |event|
        (RabbitFeed.event_routing.handle_event event).should eq event.payload
      end
    end

    it 'raises a routing error when the event cannot be routed' do
      events = [
        (Event.new 'dummy_9', '1.0.0', 'event_1', 1),
        (Event.new 'dummy_1', '1.0.9', 'event_2', 2),
        (Event.new 'dummy_1', '2.0.0', 'event_9', 3),
      ]
      events.each do |event|
        expect{ RabbitFeed.event_routing.handle_event event }.to raise_error RoutingError
      end
    end

    context 'when the version specification is invalid' do

      it 'raises a configuration error' do
        expect do
          EventRouting do
            accept_from(application: 'dummy_1', version: '1.0.b') {}
          end
        end.to raise_error ConfigurationError
      end
    end

    context 'when the event action does not provide the event' do

      it 'raises a configuration error' do
        expect do
          EventRouting do
            accept_from(application: 'dummy_1', version: '1.0.1') do
              event('dummy_1') {}
            end
          end
        end.to raise_error ConfigurationError
      end
    end
  end
end
