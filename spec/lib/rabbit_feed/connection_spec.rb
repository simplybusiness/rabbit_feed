require 'spec_helper'

module RabbitFeed
  describe Connection do
    let(:bunny_connection) { double(:bunny_connection, start: nil, open?: true) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
    end
    after do
      Connection.reconnect!
    end

    describe '.open' do

      it 'yields a connection' do
        connection = nil
        described_class.open{|c| connection = c }
        connection.should be_a Connection
      end

      context 'when the connection is not open' do
        before do
          allow(bunny_connection).to receive(:open?).and_return(false, true)
        end

        it 'resets the connection' do
          expect(bunny_connection).to receive(:close)

          connection = nil
          described_class.open{|c| connection = c }
          connection.open?.should be_true
        end
      end
    end

    describe '.reconnect!' do

      it 'removes the reference to the connection pool' do
        Connection.instance_variable_set(:@connection_pool, double(:connection_pool))
        Connection.instance_variable_get(:@connection_pool).should_not be_nil
        Connection.reconnect!
        Connection.instance_variable_get(:@connection_pool).should be_nil
      end
    end

    describe '.new' do
      subject { described_class.new (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment) }

      its(:connection)    { should_not be_nil }
      its(:configuration) { should_not be_nil }
    end

    describe '#reset' do
      subject { described_class.new (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment) }

      it 'closes the old connection and opens a new connection' do
        subject.instance_variable_set(:@connection, double(:old_bunny_connection, close: nil))
        subject.reset
        subject.connection.should eq bunny_connection
      end

      context 'when closing raises an exception' do

        it 'traps the exception' do
          allow(bunny_connection).to receive(:close).and_raise('Closing time')
          expect{ subject.reset }.to_not raise_error
        end
      end

      context 'when opening raises an exception' do

        context 'less than three times' do

          it 'traps the exception' do
            pending
          end
        end

        context 'more than three times' do

          it 'raises the exception' do
            pending
          end
        end
      end
    end

    describe '#open?' do
      subject { described_class.new (Configuration.load RabbitFeed.configuration_file_path, RabbitFeed.environment) }

      it 'returns true if the connection is open' do
        subject.open?.should be_true
      end
    end
  end
end
