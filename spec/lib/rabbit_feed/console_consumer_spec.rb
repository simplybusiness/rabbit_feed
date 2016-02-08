require 'rabbit_feed/console_consumer'
require 'rabbit_feed/testing_support/test_rabbit_feed_consumer'

module RabbitFeed
  describe ConsoleConsumer do
    let(:queue_depth) { 0 }
    let(:queue) { double(:queue, queue_depth: queue_depth) }
    before do
      allow(ConsumerConnection).to receive(:instance).and_return(queue)
      allow(STDIN).to receive(:gets).and_return('n')
    end

    describe '#init' do

      it 'prints a welcome message' do
        expect{ subject.init }.to output(
/RabbitFeed console starting at .* UTC\.\.\.
Environment: test
Queue: test\.rabbit_feed_console
Ready\. Press CTRL\+C to exit\./).to_stdout
      end

      context 'when there are messages on the rabbit_feed_console queue' do
        let(:queue_depth) { 1 }

        it 'asks to purge the queue' do
          expect{ subject.init }.to output(
/There are currently 1 message\(s\) in the console's queue\.
Would you like to purge the queue before proceeding\? \(y\/N\)>/).to_stdout
        end
      end

    end

    describe 'receiving a message' do
      let(:event) { Event.new({name: 'name'},{key: :value}) }
      before { subject.init }

      it 'prints the message' do
        expect{ rabbit_feed_consumer.consume_event event }.to output(
/-----------------------------------------------name: -----------------------------------------------
#Event metadata
name: name
(\*)+
#Event payload
key: value
----------------------------------------------------------------------------------------------------
1 events received\./).to_stdout
      end
    end
  end
end
