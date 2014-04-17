require 'spec_helper'

module RabbitFeed
  describe ProducerConnection do
    let(:bunny_exchange)   { double(:bunny_exchange, on_return: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, exchange: bunny_exchange) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end
    subject { described_class.new (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment) }

    describe '.new' do

      it 'sets up returned message handling' do
        expect(described_class).to receive(:handle_returned_message).with('return_info', 'content')
        expect(bunny_exchange).to receive(:on_return).and_yield('return_info', 'properties', 'content')
        subject
      end
    end

    describe '.handle_returned_message' do

      it 'notifies Airbrake of the return' do
        expect(Airbrake).to receive(:notify)
        described_class.handle_returned_message 1, 2
        pending 'Need to log message and send message to Airbrake'
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

      it 'publishes the message' do
        expect(bunny_exchange).to receive(:publish)
        subject.publish nil, nil
        pending 'Need to determine format of message'
      end
    end
  end
end
