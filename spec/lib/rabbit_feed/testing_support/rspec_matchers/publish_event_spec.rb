module RabbitFeed
  module TestingSupport
    module RSpecMatchers
      describe PublishEvent do
        let(:event_name) { 'test_event' }
        let(:event_payload) { { 'field' => 'value' } }
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
            expect do
              RabbitFeed::Producer.publish_event event_name, event_payload
            end.to publish_event(event_name, event_payload)
          end.to change { TestingSupport.published_events.count }.from(10).to(1)
        end

        context 'when the expectation is met' do
          it 'validates' do
            expect do
              RabbitFeed::Producer.publish_event event_name, event_payload
            end.to publish_event(event_name, event_payload)
          end

          it 'validates the negation' do
            expect do
              RabbitFeed::Producer.publish_event 'different name', {}
            end.to_not publish_event(event_name, {})
          end

          it 'traps exceptions' do
            expect do
              raise 'this hurts me more than it hurts you'
            end.to_not publish_event(event_name, {})
          end

          context 'when not validating the payload' do
            it 'validates' do
              expect do
                RabbitFeed::Producer.publish_event event_name, event_payload
              end.to publish_event(event_name)
            end

            it 'validates the negation' do
              expect do
                RabbitFeed::Producer.publish_event 'different name', {}
              end.to_not publish_event(event_name)
            end
          end
        end

        it 'validates the event name' do
          matcher = described_class.new(event_name, {})
          block   = proc { RabbitFeed::Producer.publish_event 'different name', {} }
          (matcher.matches? block).should be_falsey
        end

        context 'with block' do
          it 'validates block' do
            expect do
              RabbitFeed::Producer.publish_event event_name, event_payload
            end.to publish_event(event_name, nil) do |actual_payload|
              expect(actual_payload['field']).to eq 'value'
            end
          end

          it 'validates block with `with` will be ignored' do
            eval_block = proc do |actual_payload|
              expect(actual_payload['field']).to eq 'value'
            end
            matcher = described_class.new(event_name, nil).with(field: 'different name')
            block   = proc { RabbitFeed::Producer.publish_event event_name, 'field' => 'value' }

            (matcher.matches? block, &eval_block).should be true
          end

          it 'does not evaluates block with {}' do
            expect do
              RabbitFeed::Producer.publish_event event_name, event_payload
            end.to publish_event(event_name, nil) { |_actual_payload|
              raise 'this block should not be evaluated'
            }
          end

          it 'does not evaluate block if the expectation block does not return actual payload' do
            expect do
              nil
            end.not_to publish_event(event_name, nil) do |_actual_payload|
              raise 'this block should not be evaluated'
            end
          end
        end

        context 'when validating the payload' do
          context 'and the payload is not a Proc' do
            it 'validates the event payload' do
              matcher = described_class.new(event_name, event_payload)
              block   = proc { RabbitFeed::Producer.publish_event event_name, 'field' => 'different value' }
              (matcher.matches? block).should be_falsey
            end
          end

          context 'uses .with' do
            context 'and it is not a Proc' do
              it 'validates the event payload' do
                matcher = described_class.new(event_name, nil).with(event_payload)
                block   = proc { RabbitFeed::Producer.publish_event event_name, 'field' => 'different value' }
                (matcher.matches? block).should be false
              end
            end

            context 'and it is a Proc' do
              it 'validates the event payload' do
                matcher = described_class.new(event_name, nil).with { event_payload }
                block   = proc { RabbitFeed::Producer.publish_event event_name, 'field' => 'different value' }
                (matcher.matches? block).should be false
              end
            end
          end
        end
      end
    end
  end
end
