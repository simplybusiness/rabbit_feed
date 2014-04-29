require 'spec_helper'

module RabbitFeed
  describe Connection do
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true, close: nil) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end

    describe '.open' do

      it 'yields a connection' do
        connection = nil
        described_class.open{|c| connection = c }
        connection.should be_a Connection
      end

      context 'when the operation raises' do

        it 'resets the connection' do
          expect(bunny_connection).to receive(:close).twice

          expect{ described_class.open{ raise 'Opening connection' } }.to raise_error RuntimeError
        end
      end

      context 'when the connection is not open' do
        before do
          allow(bunny_connection).to receive(:open?).and_return(false, true)
        end

        it 'resets the connection' do
          expect(bunny_connection).to receive(:close).twice

          connection = nil
          described_class.open{|c| connection = c }
          connection.open?.should be_true
        end
      end
    end

    describe '.reconnect!' do

      it 'closes the existing connections' do
        described_class.open {}
        expect(bunny_connection).to receive(:close).at_least(:once)
        Connection.reconnect!
      end

      it 'removes the reference to the connection pool' do
        Connection.instance_variable_set(:@connection_pool, double(:connection_pool, shutdown: nil))
        Connection.instance_variable_get(:@connection_pool).should_not be_nil
        Connection.reconnect!
        Connection.instance_variable_get(:@connection_pool).should be_nil
      end
    end

    describe '.new' do
      its(:connection)    { should_not be_nil }

      context 'when opening raises an exception' do

        context 'less than three times' do

          it 'traps the exception' do
            tries = 0
            bunny_connection.stub(:start) { (tries += 1) < 3 ? (raise RuntimeError.new 'Opening time') : nil }
            expect{ subject.reset }.to_not raise_error
          end
        end

        context 'three or more times' do

          it 'raises the exception' do
            allow(bunny_connection).to receive(:start).exactly(3).times.and_raise('Opening time')
            expect{ subject }.to raise_error RuntimeError, 'Opening time'
          end
        end
      end
    end

    describe '#close' do

      it 'closes the connection' do
        expect(bunny_connection).to receive(:close)
        subject.close
      end

      context 'when closing raises an exception' do

        it 'traps the exception' do
          expect(bunny_connection).to receive(:close).and_raise('Closing time')
          expect{ subject.close }.to_not raise_error
        end
      end
    end

    describe '#reset' do

      it 'closes the old connection and opens a new connection' do
        subject.instance_variable_set(:@connection, double(:old_bunny_connection, close: nil))
        subject.reset
        subject.connection.should eq bunny_connection
      end
    end

    describe '#open?' do

      it 'returns true if the connection is open' do
        subject.open?.should be_true
      end
    end
  end
end
