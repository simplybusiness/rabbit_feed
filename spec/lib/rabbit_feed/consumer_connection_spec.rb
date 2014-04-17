require 'spec_helper'

module RabbitFeed
  describe ConsumerConnection do
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, acknowledge: nil)}
    let(:bunny_queue)      { double(:bunny_queue, channel: bunny_channel, bind: nil, subscribe: nil)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil, queue: bunny_queue) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end
    subject { described_class.new (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment) }

    describe '.new' do

      it 'binds the queue to the exchange' do
        expect(bunny_queue).to receive(:bind).with('amq.topic')
        subject
      end
    end

    describe '#consume' do
      before do
        allow(bunny_queue).to receive(:subecribe).and_yield(double(:delivery_info, delivery_tag: :tag), 'properties', 'payload')
      end

      it 'yields the payload' do
        subject.consume { |payload| payload.should eq 'payload'}
      end

      it 'preserves message order' do
        expect(bunny_channel).to receive(:prefetch).with(1)
        subject.consume {}
      end
    end
  end
end
