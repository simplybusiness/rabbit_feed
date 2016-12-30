require 'rabbit_feed/console_consumer'

module RabbitFeed
  describe ConsoleConsumer do
    let(:purge) { 'n' }
    let(:queue_depth) { 0 }
    let(:connection) { double(:connection, queue_depth: queue_depth) }
    before do
      allow(ConsumerConnection).to receive(:instance).and_return(connection)
      allow(STDIN).to receive(:gets).and_return(purge)
    end

    describe '#init' do
      it 'prints a welcome message' do
        expect { subject.init }.to output(
          /RabbitFeed console starting at .* UTC\.\.\.\s+Environment: test\s+Queue: test\.rabbit_feed_console\s+Ready\. Press CTRL\+C to exit\./
        ).to_stdout
      end

      context 'when there are events on the rabbit_feed_console queue' do
        let(:queue_depth) { 1 }

        it 'asks to purge the queue' do
          expect { subject.init }.to output(
            %r{There are currently 1 message\(s\) in the console's queue\.\s+Would you like to purge the queue before proceeding\? \(y\/N\)>}
          ).to_stdout
        end

        context 'when the user wishes to purge the queue' do
          let(:purge) { 'y' }

          it 'purges the queue' do
            expect(connection).to receive(:purge_queue)
            expect { subject.init }.to output(/Queue purged\./).to_stdout
          end
        end
      end
    end

    describe 'receiving an event' do
      let(:event) { Event.new({ name: 'name' }, key: :value) }
      before { subject.init }

      it 'prints the event' do
        expect { rabbit_feed_consumer.consume_event event }.to output(
/-----------------------------------------------name: -----------------------------------------------
#Event metadata
name: name
(\*)+
#Event payload
key: value
----------------------------------------------------------------------------------------------------
1 events received\./
        ).to_stdout
      end
    end
  end
end
