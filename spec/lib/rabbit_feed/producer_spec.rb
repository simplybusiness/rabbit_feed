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
              field('field', type: 'string', definition: 'The definition of the field', sensitive: true)
            end
          end
        end
      end
      subject { RabbitFeed::Producer.publish_event event_name, 'field' => 'value' }

      context 'when event definitions are not set' do
        before { RabbitFeed::Producer.event_definitions = nil }

        it 'raises an error' do
          expect { subject }.to raise_error Error
        end
      end

      context 'when no event definition is found' do
        let(:event_name) { 'different event name' }

        it 'raises an error' do
          expect { subject }.to raise_error Error
        end
      end

      it 'returns the event' do
        expect(subject).to be_a Event
      end

      it 'sets the sensitive fields for the event' do
        expect(subject.sensitive_fields).to match_array(['field'])
      end

      it 'sets the event metadata' do
        Timecop.freeze(Time.gm(1990)) do
          expect(subject.metadata).to match('application' => 'rabbit_feed',
                                            'created_at_utc' => '1990-01-01T00:00:00.000000Z',
                                            'environment'    => 'test',
                                            'host'           => an_instance_of(String),
                                            'name'           => 'event_name',
                                            'schema_version' => Event::SCHEMA_VERSION,
                                            'version'        => '1.0.0')
        end
      end

      it 'serializes the event and provides message metadata' do
        Timecop.freeze do
          expect(ProducerConnection.instance).to receive(:publish).with(
            an_instance_of(String),
            routing_key: 'test.rabbit_feed.event_name',
            type:        'event_name',
            app_id:      'rabbit_feed',
            timestamp:   Time.now.utc.to_i
          )
          subject
        end
      end

      context 'when a route_prefix_extension is set' do
        before { RabbitFeed.environment = 'test_route_prefix_extension' }
        after  { reset_environment }

        it 'appends the route_prefix_extension to the routing_key' do
          Timecop.freeze do
            expect(ProducerConnection.instance).to receive(:publish) do |_, options|
              expect(options[:routing_key]).to eq 'test_route_prefix_extension.foobar.rabbit_feed.event_name'
            end
            subject
          end
        end
      end
    end

    describe '.publish_event' do
      let(:event_name) { 'event_name' }
      let(:app_name) { 'Some_application_name' }
      before do
        allow(RabbitFeed::ProducerConnection).to receive(:publish)
        EventDefinitions do
          define_event('event_name', version: '1.0.0') do
            defined_as do
              'The definition of the event'
            end
            payload_contains do
              field('field', type: 'string', definition: 'The definition of the field', sensitive: true)
            end
          end
        end
      end

      it 'uses the default application found in RabbitFeed.configuration.application if no application argument is given' do
        expect(ProducerConnection.instance).to receive(:publish) do |_, options|
          expect(options[:app_id]).to eq 'rabbit_feed'
        end
        RabbitFeed::Producer.publish_event event_name, 'field' => 'value'
      end

      it 'uses the application given passed in as an argument' do
        expect(ProducerConnection.instance).to receive(:publish) do |_, options|
          expect(options[:app_id]).to eq app_name
        end
        RabbitFeed::Producer.publish_event(event_name, {'field' => 'value'}, app_name)
      end
    end
  end
end
