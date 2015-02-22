require 'spec_helper'

module RabbitFeed
  module TestingSupport
    describe TestingHelpers do
      describe 'consuming events' do
        accumulator = []

        let(:define_route) do
          EventRouting do
            accept_from('some_place') do
              event('some_event') do |event|
                accumulator << event
              end
            end
          end
        end

        let(:payload)  { {'stuff' => 'some_stuff'} }
        let(:metadata) { {'application' => 'some_place', 'name' => 'some_event'} }
        let(:event)    { Event.new metadata, payload }

        before { define_route }

        it 'should allow to send messages directly to the consumer' do
          rabbit_feed_consumer.consume_event event
          expect(accumulator.size).to eq(1)
          expect(accumulator[0].payload).to eq(payload)
          expect(accumulator[0].metadata).to eq(metadata)
        end
      end
    end
  end
end
