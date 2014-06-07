require 'spec_helper'

module RabbitFeed

  describe Consumer do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, ack: nil, nack: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    let(:event)            { double(:event, application: 'rabbit_feed', name: 'test') }
    before do
      allow(Event).to receive(:deserialize).and_return(event)
      allow(Bunny).to receive(:new).and_return(bunny_connection)
      allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :test), {}, event)
    end

    describe '#run' do
      let(:error) { }
      before do
        allow(described_class).to receive(:start).and_raise(error)
      end

      context 'when a ConfigurationError is raised' do
        let(:error) { ConfigurationError.new }

        it 'raises the exception' do
          expect{ described_class.run }.to raise_error(ConfigurationError)
        end
      end

      context 'when a different error is raised' do
        let(:error) { Error.new }
        before do
          allow(described_class).to receive(:recover?).and_return(true, false)
        end

        it 'does not raise the exception' do
          expect{ described_class.run }.not_to raise_error
        end

        it 'triggers a reconnect' do
          expect(ConsumerConnection).to receive(:reconnect!).at_least(:twice)
          described_class.run
        end

        it 'recovers' do
          expect(described_class).to receive(:start).at_least(:twice)
          described_class.run
        end
      end
    end

    describe '#start' do
      subject{ described_class.start }

      it 'handles the event' do
        handled_event = nil
        EventRouting do
          accept_from('rabbit_feed') do
            event('test') {|event| handled_event = event }
          end
        end
        subject
        expect(handled_event).to eq event
      end
    end
  end
end
