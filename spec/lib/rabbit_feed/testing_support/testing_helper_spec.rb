require 'spec_helper'

module RabbitFeed
  module TestingSupport
    describe TestingHelpers do
      describe 'consuming events' do

        include TestingHelpers

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

        let(:event) { {'application' => 'some_place', 'name' => 'some_event', 'stuff' => 'some_stuff'} }

        before { define_route }

        it 'should allow to send messages directly to the consumer' do
          rabbit_feed_consumer.consume_event(event)
          expect(accumulator.size).to eq(1)
          expect(accumulator[0].payload).to eq(event)
        end
      end
    end
  end
end
