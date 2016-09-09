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

          it 'traps exceptions in negation' do
            expect {
              raise 'this hurts me more than it hurts you'
            }.to_not publish_event(event_name, {})
          end

          subject { expect { raise 'this hurts me more than it hurts you' }.to publish_event(event_name, {}) }
          it 'catches and logs exceptions when not in negation' do
            expect { subject }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /this hurts me more than it hurts you/)
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

        context 'with block' do
          it 'validates block' do
            expect {
              RabbitFeed::Producer.publish_event event_name, event_payload
            }.to publish_event(event_name, nil) do |actual_payload|
              expect(actual_payload['field']).to eq 'value'
            end
          end

          it 'validates block with `with` will be ignored' do
            eval_block  = Proc.new {|actual_payload|
              expect(actual_payload['field']).to eq 'value'
            }
            matcher = described_class.new(event_name, nil).with({field: 'different name'})
            block   = Proc.new { RabbitFeed::Producer.publish_event event_name, {'field' => 'value'} }

            (matcher.matches? block, &eval_block).should be true
          end

          it 'does not evaluates block with {}' do
            expect {
              RabbitFeed::Producer.publish_event event_name, event_payload
            }.to publish_event(event_name, nil) { |actual_payload|
              raise 'this block should not be evaluated'
            }
          end

          it 'does not evaluate block if the expectation block does not return actual payload' do
            expect {
              nil
            }.not_to publish_event(event_name, nil) do |actual_payload|
              raise 'this block should not be evaluated'
            end
          end
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
