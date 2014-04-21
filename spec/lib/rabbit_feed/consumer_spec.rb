require 'spec_helper'

module RabbitFeed

  describe Consumer do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, ack: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    let(:message)          { {} }
    before do
      RabbitFeed.message_handler_klass = 'RabbitFeed::MessageHandler'
      allow(Bunny).to receive(:new).and_return(bunny_connection)
      allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :test), {}, message)
    end

    describe '#start' do

      it 'delegates the message to the handler' do
        expect_any_instance_of(MessageHandler).to receive(:handle_message).with(message)
        subject.start
      end
    end
  end
end
