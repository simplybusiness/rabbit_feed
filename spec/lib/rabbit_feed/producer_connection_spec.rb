require 'spec_helper'

module RabbitFeed
  describe ProducerConnection do
    let(:bunny_exchange)   { double(:bunny_exchange, on_return: nil, publish: nil) }
    let(:bunny_channel)    { double(:bunny_channel, exchange: bunny_exchange, id: 1) }
    let(:bunny_connection) { double(:bunny_connection, start: nil, closed?: false, close: nil, create_channel: bunny_channel) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end
    subject do
      Class.new(described_class).instance
    end

    describe '#new' do
      it 'sets up returned message handling' do
        expect(described_class).to receive(:handle_returned_message).with('return_info', 'content')
        expect(bunny_exchange).to receive(:on_return).and_yield('return_info', 'properties', 'content')
        subject
      end
    end

    describe '#handle_returned_message' do

      context 'when Airbrake is defined' do
        before do
          stub_const('Airbrake', double(:airbrake, configuration: airbrake_configuration))
        end

        context 'and the Airbrake configuration is public' do
          let(:airbrake_configuration) { double(:airbrake_configuration, public?: true) }

          it 'notifies Airbrake of the return' do
            expect(Airbrake).to receive(:notify_or_ignore).with(an_instance_of ReturnedMessageError)
            described_class.handle_returned_message 1, 2
          end
        end
      end
    end

    describe '#publish' do
      let(:message) { 'the message' }
      let(:options) { {routing_key: 'routing_key'} }

      it 'publishes the message as mandatory and persistent' do
        expect(bunny_exchange).to receive(:publish).with(message, { persistent: true, mandatory: true, routing_key: 'routing_key' })
        subject.publish message, options
      end

      it 'is synchronized' do
        expect(subject).to receive(:synchronized).and_call_original
        subject.publish message, options
      end
    end
  end
end
