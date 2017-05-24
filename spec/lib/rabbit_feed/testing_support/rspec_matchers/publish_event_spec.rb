require 'rabbit_feed/testing_support/rspec_matchers/publish_event'

module RabbitFeed
  module TestingSupport
    module RSpecMatchers
      describe 'publish_event' do
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
            RabbitFeed::Producer.publish_event(event_name, event_payload)
          end

          expect do
            expect do
              RabbitFeed::Producer.publish_event(event_name, event_payload)
            end.to publish_event(event_name, event_payload)
          end.to change { TestingSupport.published_events.count }.from(10).to(1)
        end

        it 'traps exceptions' do
          expect do
            raise 'this hurts me more than it hurts you'
          end.to_not publish_event(event_name)
        end

        it 'validates' do
          expect do
            RabbitFeed::Producer.publish_event(event_name, event_payload)
          end.to publish_event(event_name, event_payload)

          expect do
            RabbitFeed::Producer.publish_event('different name', event_payload)
          end.to_not publish_event(event_name, event_payload)
        end

        context 'when not validating the payload' do
          it 'validates the event name' do
            expect do
              RabbitFeed::Producer.publish_event(event_name, event_payload)
            end.to publish_event(event_name)

            expect do
              RabbitFeed::Producer.publish_event('different name', {})
            end.to_not publish_event(event_name)
          end
        end

        context 'when validating the payload' do
          it 'validates the event payload' do
            expect do
              RabbitFeed::Producer.publish_event(event_name, 'field' => 'different value')
            end.not_to publish_event(event_name, event_payload)

            expect do
              RabbitFeed::Producer.publish_event(event_name, event_payload)
            end.to publish_event(event_name, event_payload)
          end

          context 'using .including' do
            context 'when there is an earlier payload provided' do
              it 'prefers the earlier payload' do
                expect do
                  RabbitFeed::Producer.publish_event(event_name, 'field' => 'different value')
                end.not_to publish_event(event_name, event_payload).including(event_payload)
              end
            end

            it 'validates the event payload' do
              expect do
                RabbitFeed::Producer.publish_event(event_name, event_payload)
              end.not_to publish_event(event_name).including('field' => 'different value')

              expect do
                RabbitFeed::Producer.publish_event(event_name, event_payload)
              end.to publish_event(event_name).including(event_payload)
            end

            context 'when the actual payload contains more fields than the expected payload' do
              it 'validates the event payload' do
                expect do
                  RabbitFeed::Producer.publish_event(event_name, event_payload.merge('different field' => 'value'))
                end.to publish_event(event_name).including(event_payload)
              end
            end

            context 'when the expected payload contains more fields than the actual payload' do
              it 'invalidates the event payload' do
                expect do
                  RabbitFeed::Producer.publish_event(event_name, event_payload)
                end.not_to publish_event(event_name).including(event_payload.merge('different field' => 'value'))
              end
            end
          end

          context 'using .asserting' do
            context 'when there is an earlier payload provided' do
              it 'prefers the earlier payload' do
                expect do
                  RabbitFeed::Producer.publish_event(event_name, 'field' => 'different value')
                end.not_to(publish_event(event_name, event_payload).asserting { |actual_payload| expect(actual_payload).to eq(event_payload) })

                expect do
                  RabbitFeed::Producer.publish_event(event_name, 'field' => 'different value')
                end.not_to(publish_event(event_name, event_payload).asserting { |actual_payload| expect(actual_payload).not_to eq(event_payload) })
              end
            end

            it 'performs the assertion' do
              expect do
                RabbitFeed::Producer.publish_event(event_name, event_payload)
              end.to(publish_event(event_name).asserting { |actual_payload| expect(actual_payload).to eq(event_payload) })

              expect do
                RabbitFeed::Producer.publish_event(event_name, event_payload)
              end.to(publish_event(event_name).asserting { |actual_payload| expect(actual_payload).not_to eq('field' => 'different value') })
            end
          end
        end
      end
    end
  end
end
