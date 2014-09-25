require 'spec_helper'

module RabbitFeed
  describe Connection do
    let(:bunny_exchange)    { double(:bunny_exchange, on_return: nil) }
    let(:connection_closed) { false }
    let(:bunny_channel)     { double(:bunny_channel, exchange: bunny_exchange, id: 1) }
    let(:bunny_connection)  { double(:bunny_connection, start: nil, closed?: connection_closed, close: nil, create_channel: bunny_channel) }
    before { allow(Bunny).to receive(:new).and_return(bunny_connection) }
    after do
      subject.instance_variable_set(:@connection, nil)
      subject.instance_variable_set(:@connection_pool, nil)
    end
    subject { RabbitFeed::ProducerConnection }

    describe '.connection' do

      it 'retries on exception' do
        expect(subject).to receive(:retry_on_exception)
        subject.connection
      end

      it 'returns the connection' do
        expect(subject.connection).to eq bunny_connection
      end

      it 'assigns the connection' do
        subject.connection
        expect(subject.instance_variable_get(:@connection)).to eq bunny_connection
      end
    end

    describe '.connection_pool' do

      it 'returns the connection pool' do
        expect(subject.connection_pool).to be_a ConnectionPool
      end

      it 'assigns the connection pool' do
        subject.connection_pool
        expect(subject.instance_variable_get(:@connection_pool)).to be_a ConnectionPool
      end
    end

    describe '.open' do

      it 'provides an instance of the class' do
        actual = subject.open{|connection| connection }
        expect(actual).to be_a subject
      end
    end

    describe '.closed?' do

      context 'when the connection is nil' do

        it 'returns false' do
          expect(subject.closed?).to be_false
        end
      end

      context 'when the connection is not nil' do
        let(:connection_closed) { 'status' }
        before{ subject.connection }

        it 'returns the closed status of the connection' do
          expect(subject.closed?).to eq 'status'
        end
      end
    end

    describe '.close' do

      context 'when the connection is nil' do

        it 'does not close the connection' do
          expect(bunny_connection).not_to receive(:close)
          subject.close
        end
      end

      context 'when the connection is not nil' do
        before do
          subject.connection
          subject.connection_pool
        end

        context 'when the connection is closed' do
          let(:connection_closed) { true }

          it 'does not close the connection' do
            expect(bunny_connection).not_to receive(:close)
            subject.close
          end
        end

        context 'when the connection is not closed' do
          let(:connection_closed) { false }

          it 'closes the connection' do
            expect(bunny_connection).to receive(:close)
            subject.close
          end

          context 'when closing raises an exception' do

            it 'does not propogate the exception' do
              allow(bunny_connection).to receive(:close).and_raise 'error'
              expect{ subject.close }.not_to raise_error
            end
          end
        end

        it 'unsets the connection' do
          subject.close
          expect(subject.instance_variable_get(:@connection)).to be_nil
        end

        it 'unsets the connection pool' do
          subject.close
          expect(subject.instance_variable_get(:@connection_pool)).to be_nil
        end
      end
    end

    describe '.retry_on_exception' do
      it_behaves_like 'an operation that retries on exception', :retry_on_exception, RuntimeError
      it_behaves_like 'an operation that does not retry on exception', :retry_on_exception, Bunny::ConnectionClosedError
    end

    describe '.retry_on_closed_connection' do
      before do
        subject.connection
        subject.connection_pool
      end

      it_behaves_like 'an operation that retries on exception', :retry_on_closed_connection, Bunny::ConnectionClosedError
      it_behaves_like 'an operation that does not retry on exception', :retry_on_closed_connection, RuntimeError

      it 'unsets the connection' do
        expect { subject.retry_on_closed_connection { raise Bunny::ConnectionClosedError.new 'blah' } }.to raise_error
        expect(subject.instance_variable_get(:@connection)).to be_nil
      end

      it 'unsets the connection pool' do
        expect { subject.retry_on_closed_connection { raise Bunny::ConnectionClosedError.new 'blah' } }.to raise_error
        expect(subject.instance_variable_get(:@connection_pool)).to be_nil
      end
    end
  end
end
