require 'spec_helper'

module RabbitFeed
  describe ProducerConnection do
    let(:bunny_exchange)   { double(:bunny_exchange, on_return: nil) }
    let(:bunny_channel)    { double(:bunny_channel, exchange: bunny_exchange) }
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, create_channel: bunny_channel) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end

    describe '.handle_returned_message' do

      it 'notifies Airbrake of the return' do
        expect(Airbrake).to receive(:notify_or_ignore).with(an_instance_of ReturnedMessageError)
        described_class.handle_returned_message 1, 2
      end
    end

    describe '#publish' do
      let(:message) { 'the message' }
      let(:options) { {routing_key: 'routing_key'} }

      it 'publishes the message as mandatory and peristent' do
        expect(bunny_exchange).to receive(:publish).with(message, { persistent: true, mandatory: true, routing_key: 'routing_key' })
        described_class.publish message, options
      end

      context 'when publishing raises an exception' do

        context 'less than three times' do

          it 'traps the exception' do
            tries = 0
            bunny_exchange.stub(:publish) { (tries += 1) < 3 ? (raise RuntimeError.new 'Publishing time') : nil }
            expect{ described_class.publish message, options }.to_not raise_error
          end
        end

        context 'three or more times' do

          it 'raises the exception' do
            allow(bunny_exchange).to receive(:publish).exactly(3).times.and_raise('Publishing time')
            expect{ described_class.publish message, options }.to raise_error RuntimeError, 'Publishing time'
          end
        end
      end
    end
  end
end
