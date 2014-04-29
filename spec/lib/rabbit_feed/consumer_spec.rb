require 'spec_helper'

module RabbitFeed

  describe Consumer do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, ack: nil, nack: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    let(:event)            { Event.new 'rabbit_feed', '1.0.0', 'test', { key: :value } }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
      allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :test), {}, event.serialize)
    end

    describe '#start' do
      subject{ described_class.start }

      it 'handles the event' do
        handled_event = nil
        EventRouting do
          accept_from(application: 'rabbit_feed', version: '1.0.0') do
            event('test') {|event| handled_event = event }
          end
        end
        subject
        expect(handled_event).to be_a Event
      end
    end
  end
end
