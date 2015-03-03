require 'spec_helper'

module RabbitFeed
  describe EventRouting do
    before do
      EventRouting do
        accept_from('dummy_1') do
          event('event_1') do |event|
            event.payload
          end
          event('event_2') do |event|
            event.payload
          end
        end
        accept_from('dummy_2') do
          event('event_3') do |event|
            event.payload
          end
        end
        accept_from(:any) do
          event('event_3') do |event|
            raise 'event_3 from any app'
          end
          event('event_4') do |event|
            event.payload
          end
        end
      end
    end

    it 'should create routing keys for the specified routes' do

      RabbitFeed::Consumer.event_routing.accepted_routes.should =~ %w{
        test.dummy_1.event_1
        test.dummy_1.event_2
        test.dummy_2.event_3
        test.*.event_3
        test.*.event_4
      }
    end

    it 'routes the event to the correct action, preferring named applications' do
      events = [
        Event.new({application: 'dummy_1', name: 'event_1'}, {payload: 1}),
        Event.new({application: 'dummy_1', name: 'event_2'}, {payload: 2}),
        Event.new({application: 'dummy_1', name: 'event_4'}, {payload: 4}),
        Event.new({application: 'dummy_2', name: 'event_3'}, {payload: 3}),
        Event.new({application: 'none',    name: 'event_4'}, {payload: 4}),
      ]
      events.each do |event|
        (RabbitFeed::Consumer.event_routing.handle_event event).should eq event.payload
      end
    end

    it 'raises a routing error when the event cannot be routed' do
      events = [
        Event.new({application: 'dummy_9', name: 'event_1'}, {payload: 1}),
        Event.new({application: 'dummy_1', name: 'event_9'}, {payload: 3}),
      ]
      events.each do |event|
        expect{ RabbitFeed::Consumer.event_routing.handle_event event }.to raise_error RoutingError
      end
    end

    describe EventRouting::Application do
      let(:name) { 'name' }
      subject{ EventRouting::Application.new name }

      it { should be_valid }

      context 'when the name is nil' do
        let(:name) {}

        it 'raises a configuration error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end
    end

    describe EventRouting::Event do
      let(:name)  { 'name' }
      let(:block) { Proc.new{|event|} }
      subject{ EventRouting::Event.new name, block }

      it { should be_valid }

      context 'when the name is nil' do
        let(:name) {}

        it 'raises a configuration error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end

      context 'when no action is provided' do
        let(:block) {}

        it 'raises a configuration error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end

      context 'when the event is not provided to the event action' do
        let(:block) { Proc.new{} }

        it 'raises a configuration error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end
    end

    context 'testing cumulative routing definitions' do
      before do
        EventRouting do
          accept_from('dummy_3') do
            event('event_4') do |event|
              event.payload
            end
          end
        end
      end

      it 'applies routing definitions in a cumulative manner' do
        RabbitFeed::Consumer.event_routing.accepted_routes.should =~ %w{
          test.dummy_1.event_1
          test.dummy_1.event_2
          test.dummy_2.event_3
          test.dummy_3.event_4
          test.*.event_3
          test.*.event_4
        }
      end
    end

    context 'defining the same application twice' do

      it 'raises an exception for a named application' do
        expect do
          EventRouting do
            accept_from('dummy_2') do
              event('event_4') do |event|
                event.payload
              end
            end
          end
        end.to raise_error ConfigurationError
      end

      it 'raises an exception for the catch-all application' do
        expect do
          EventRouting do
            accept_from(:any) do
              event('event_4') do |event|
                event.payload
              end
            end
          end
        end.to raise_error ConfigurationError
      end
    end
  end
end
