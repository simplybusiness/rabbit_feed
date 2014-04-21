require 'spec_helper'

module RabbitFeed

  describe Consumer do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, ack: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    let(:event)            { Event.new :rabbit_feed, '1.0.0', :test_event, { key: :value } }
    before do
      RabbitFeed.event_handler_klass = 'RabbitFeed::EventHandler'
      allow(Bunny).to receive(:new).and_return(bunny_connection)
      allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :test), {}, event.serialize)
    end

    describe '#start' do

      it 'delegates the event to the handler' do
        expect_any_instance_of(EventHandler).to receive(:handle_event).with(:test_event, { key: :value })
        subject.start
      end
    end
  end
end
