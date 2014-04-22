require 'spec_helper'

module RabbitFeed
  describe EventRouting do
    before do
      @existing_routing = RabbitFeed.event_routing

      EventRouting do
        accept_from(application: 'dummy_1', version: '1') do
          event('event_1')
          event('event_2')
        end
        accept_from(application: 'dummy_1', version: '2') do
          event('event_3')
          event('event_4')
        end
        accept_from(application: 'dummy_2', version: '2') do
          event('event_5')
        end
      end
    end
    after do
      RabbitFeed.event_routing = @existing_routing
    end

    it 'should create routing keys for the specified routes' do

      RabbitFeed.event_routing.accepted_routes.should =~ %w{
        test.dummy_1.1.event_1
        test.dummy_1.1.event_2
        test.dummy_1.2.event_3
        test.dummy_1.2.event_4
        test.dummy_2.2.event_5
      }
    end
  end
end
