require 'spec_helper'

module RabbitFeed
  describe ProducerConnection do
    let(:bunny_exchange)   { double(:bunny_exchange, on_return: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, exchange: bunny_exchange) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end

    describe '.new' do

      it 'sets up returned message handling' do
        expect(described_class).to receive(:handle_returned_message).with('return_info', 'content')
        expect(bunny_exchange).to receive(:on_return).and_yield('return_info', 'properties', 'content')
        subject
      end
    end

    describe '.handle_returned_message' do

      it 'notifies Airbrake of the return' do
        expect(Airbrake).to receive(:notify).with(an_instance_of ReturnedMessageError)
        described_class.handle_returned_message 1, 2
      end
    end

    describe '#close' do

      it 'unsets the exchange' do
        subject
        subject.instance_variable_get(:@exchange).should_not be_nil
        subject.close
        subject.instance_variable_get(:@exchange).should be_nil
      end
    end

    describe '#publish' do
      let(:message)     { 'the message' }
      let(:routing_key) { 'routing_key' }

      it 'publishes the message' do
        expect(bunny_exchange).to receive(:publish).with(message, { persistent: true, mandatory: true, routing_key: 'routing_key' })
        described_class.publish message, routing_key
      end

      context 'when publishing raises an exception' do

        context 'less than three times' do

          it 'traps the exception' do
            tries = 0
            bunny_exchange.stub(:publish) { (tries += 1) < 3 ? (raise RuntimeError.new 'Publishing time') : nil }
            expect{ described_class.publish message, routing_key }.to_not raise_error
          end
        end

        context 'three or more times' do

          it 'raises the exception' do
            allow(bunny_exchange).to receive(:publish).exactly(3).times.and_raise('Publishing time')
            expect{ described_class.publish message, routing_key }.to raise_error RuntimeError, 'Publishing time'
          end
        end
      end
    end
  end
end
