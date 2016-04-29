module RabbitFeed
  module TestingSupport
    module RSpecMatchers
      describe PublishEvent do
        let(:event_name) { 'test_event' }
        let(:event_payload) { {'field' => 'value'} }
        TestingSupport.capture_published_events self
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

        it 'clears any existing published_events' do
          10.times.each do
            RabbitFeed::Producer.publish_event event_name, event_payload
          end

          expect do
            expect {
              RabbitFeed::Producer.publish_event event_name, event_payload
            }.to publish_event(event_name, event_payload)
          end.to change { TestingSupport.published_events.count }.from(10).to(1)

        end

        context 'when the expectation is met' do
          it 'validates' do
            expect {
              RabbitFeed::Producer.publish_event event_name, event_payload
            }.to publish_event(event_name, event_payload)
          end

          it 'validates the negation' do
            expect {
              RabbitFeed::Producer.publish_event 'different name', {}
            }.to_not publish_event(event_name, {})
          end

          it 'traps exceptions' do
            expect {
              raise 'this hurts me more than it hurts you'
            }.to_not publish_event(event_name, {})
          end

          context 'when not validating the payload' do
            it 'validates' do
              expect {
                RabbitFeed::Producer.publish_event event_name, event_payload
              }.to publish_event(event_name)
            end

            it 'validates the negation' do
              expect {
                RabbitFeed::Producer.publish_event 'different name', {}
              }.to_not publish_event(event_name)
            end
          end
        end

        it 'validates the event name' do
          matcher = described_class.new(event_name, {})
          block   = Proc.new { RabbitFeed::Producer.publish_event 'different name', {} }
          (matcher.matches? block).should be_falsey
        end

        context 'when validating the payload' do
          context 'and the payload is not a Proc' do
            it 'validates the event payload' do
              matcher = described_class.new(event_name, event_payload)
              block   = Proc.new { RabbitFeed::Producer.publish_event event_name, {'field' => 'different value'} }
              (matcher.matches? block).should be_falsey
            end
          end

          context 'uses .with' do
            context 'with regex matcher' do
              it 'validates the event payload' do
                matcher = described_class.new(event_name, nil).with(/value/)
                block   = Proc.new { RabbitFeed::Producer.publish_event event_name, event_payload }
                (matcher.matches? block).should be true
              end
            end

            context 'and it is not a Proc' do
              it 'validates the event payload' do
                matcher = described_class.new(event_name, nil).with(event_payload)
                block   = Proc.new { RabbitFeed::Producer.publish_event event_name, {'field' => 'different value'} }
                (matcher.matches? block).should be false
              end
            end

            context 'and it is a Proc' do
              it 'validates the event payload' do
                matcher = described_class.new(event_name, nil).with{event_payload}
                block   = Proc.new { RabbitFeed::Producer.publish_event event_name, {'field' => 'different value'} }
                (matcher.matches? block).should be false
              end
            end
          end
        end
      end
    end
  end
end
