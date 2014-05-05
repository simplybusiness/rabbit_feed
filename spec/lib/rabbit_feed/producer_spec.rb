require 'spec_helper'

module RabbitFeed
  describe Producer do
    describe '.publish' do
      let(:event_name) { 'event_name' }
      before do
        RabbitFeed::Producer.stub!
        EventDefinitions do
          define_event('event_name', version: '1.0.0') do
            defined_as do
              'The definition of the event'
            end
            payload_contains do
              field('field', type: 'string', definition: 'The definition of the field')
            end
          end
        end
      end
      subject{ RabbitFeed::Producer.publish_event event_name, { 'field' => 'value' } }

      context 'when event definitions are not set' do
        before{ RabbitFeed::Producer.event_definitions = nil }

        it 'raises an error' do
          expect{ subject }.to raise_error Error
        end
      end

      context 'when no event definition is found' do
        let(:event_name) { 'different event name' }

        it 'raises an error' do
          expect{ subject }.to raise_error Error
        end
      end

      it 'returns the event' do
        expect(subject).to be_a Event
      end

      it 'serializes the event and provides a routing key' do
        expect(ProducerConnection).to receive(:publish).with(an_instance_of(String), 'test.rabbit_feed.event_name')
        subject
      end
    end
  end
end
