require 'spec_helper'

module RabbitFeed
  describe Producer do
    describe '.publish' do
      let(:event_name) { 'event_name' }
      before do
        allow(RabbitFeed::ProducerConnection).to receive(:publish)
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

      it 'serializes the event and provides message metadata' do
        Timecop.freeze do
          expect(ProducerConnection).to receive(:publish).with(
            an_instance_of(String),
            {
              routing_key: 'test.rabbit_feed.event_name',
              type:        'event_name',
              app_id:      'rabbit_feed',
              timestamp:   Time.now.utc.to_i,
              headers:     {
                'application'    => 'rabbit_feed',
                'host'           => an_instance_of(String),
                'environment'    => 'test',
                'created_at_utc' => Time.now.utc.iso8601(6),
                'version'        => '1.0.0',
                'name'           => 'event_name',
              }
            })
          subject
        end
      end
    end
  end
end
