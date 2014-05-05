require 'spec_helper'

module RabbitFeed
  module RSpecMatchers
    describe PublishEvent do
      let(:event_name)    { 'test_event' }
      let(:event_payload) {{'field' => 'value'}}
      before do
        EventDefinitions do
          define_event('test_event', version: '1.0.0') do
            defined_as do
              'The definition of a test event'
            end
            field('field', type: 'string', definition: 'field definition')
          end
          define_event('different name', version: '1.0.0') do
            defined_as do
              'The definition of a test event with a different name'
            end
          end
        end
      end

      context 'when the expectation is met' do

        it 'validates' do
          expect{
            RabbitFeed::Producer.publish_event event_name, event_payload
          }.to publish_event(event_name, event_payload)
        end

        it 'validates the negation' do
          expect{
            RabbitFeed::Producer.publish_event 'different name', {}
          }.to_not publish_event(event_name, {})
        end
      end

      it 'validates the event name' do
        matcher = described_class.new(event_name, {})
        block = Proc.new{ RabbitFeed::Producer.publish_event 'different name', {} }
        (matcher.matches? block).should be_false
      end

      it 'validates the event payload' do
        matcher = described_class.new(event_name, event_payload)
        block = Proc.new{ RabbitFeed::Producer.publish_event event_name, {'field' => 'different value'} }
        (matcher.matches? block).should be_false
      end
    end
  end
end
