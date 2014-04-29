require 'spec_helper'

module RabbitFeed
  describe ConsumerConnection do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, nack: nil, ack: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end

    describe '#reset' do
      before do
        EventRouting do
          accept_from(application: 'rabbit_feed', version: '1.0.0') do
            event('test') {|event|}
          end
        end
      end

      it 'binds the queue to the exchange' do
        expect(bunny_queue).to receive(:bind).with('amq.topic', { routing_key: 'test.rabbit_feed.1.0.0.test'})
        subject.reset
      end
    end

    describe '#consume' do
      before do
        allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :tag), 'properties', 'payload')
      end

      it 'yields the payload' do
        subject.consume { |payload| payload.should eq 'payload'}
      end

      it 'preserves message order' do
        expect(bunny_channel).to receive(:prefetch).with(1)
        subject.consume {}
      end

      context 'when an exception is raised' do

        it 'notifies airbrake' do
          expect(Airbrake).to receive(:notify).with(an_instance_of RuntimeError)

          expect{ subject.consume { raise 'Consuming time' } }.to raise_error RuntimeError
        end
      end
    end
  end
end
