module RabbitFeed
  describe ConsumerConnection do
    let(:bunny_queue)      { double(:bunny_queue, bind: nil, subscribe: nil)}
    let(:bunny_channel)    { double(:bunny_channel, prefetch: nil, nack: nil, ack: nil, queue: bunny_queue, id: 1)}
    let(:bunny_connection) { double(:bunny_connection, start: nil, closed?: false, close: nil, create_channel: bunny_channel) }
    before do
      allow(Bunny).to receive(:new).and_return(bunny_connection)
      allow(bunny_queue).to receive(:channel).and_return(bunny_channel)
    end
    subject do
      Class.new(described_class).instance
    end

    describe '#new' do
      before do
        EventRouting do
          accept_from('rabbit_feed') do
            event('test') {|event|}
          end
        end
      end

      it 'binds the queue to the exchange' do
        expect(bunny_queue).to receive(:bind).with('amq.topic', { routing_key: 'test.rabbit_feed.test'})
        subject
      end

      it 'preserves message order' do
        expect(bunny_channel).to receive(:prefetch).with(1)
        subject
      end

      context 'when a route_prefix_extension is set' do
        before { RabbitFeed.environment = 'test_route_prefix_extension' }
        after  { reset_environment }

        it 'appends the route_prefix_extension to the routing_key' do
          expect(bunny_queue).to receive(:bind).with('amq.topic',
            { routing_key: 'test_route_prefix_extension.foobar.rabbit_feed.test'}
          )
          subject
        end
      end
    end

    describe '#consume' do
      before do
        allow(bunny_queue).to receive(:subscribe).and_yield(double(:delivery_info, delivery_tag: :tag), 'properties', 'payload')
        allow_any_instance_of(described_class).to receive(:sleep)
        allow_any_instance_of(described_class).to receive(:cancel_consumer)
      end

      it 'yields the payload' do
        subject.consume { |payload| payload.should eq 'payload'}
      end

      it 'acknowledges the message' do
        expect(bunny_channel).to receive(:ack)
        subject.consume { }
      end

      it 'is synchronized' do
        expect(subject).to receive(:synchronized).and_call_original
        subject.consume { }
      end

      it 'cancels the consumer' do
        expect_any_instance_of(described_class).to receive(:cancel_consumer)
        subject.consume { }
      end

      context 'when consuming' do
        before { allow(subject.send(:mutex)).to receive(:locked?).and_return(true) }

        it 'raises when attempting to consume in parallel' do
          expect{ subject.consume { } }.to raise_error 'This connection already has a consumer subscribed'
        end
      end

      context 'when an exception is raised' do

        context 'when consumer_exit_after_fail is true' do
          before { allow(RabbitFeed.configuration).to receive(:consumer_exit_after_fail).and_return(true) }

          it 'exits the application' do
            expect_any_instance_of(described_class).to receive(:exit).with(1)
            subject.consume { raise 'Consuming time' }
          end
        end


        context 'when consumer_exit_after_fail is false' do
          before { allow(RabbitFeed.configuration).to receive(:consumer_exit_after_fail).and_return(false) }

          context 'when Airbrake is defined' do
            after { Object.send(:remove_const, ('Airbrake').to_sym) rescue NameError }

            context 'when the version is lower than 5' do
              before do
                module ::Airbrake
                  VERSION = '4.0.0'
                end
                allow(Airbrake).to receive(:configuration).and_return(airbrake_configuration)
              end

              context 'and the Airbrake configuration is public' do
                let(:airbrake_configuration) { double(:airbrake_configuration, public?: true) }

                it 'notifies airbrake' do
                  expect(Airbrake).to receive(:notify_or_ignore).with(an_instance_of RuntimeError)

                  expect{ subject.consume { raise 'Consuming time' } }.not_to raise_error
                end
              end
            end

            context 'when the version is greater than 4' do
              before do
                module ::Airbrake
                  AIRBRAKE_VERSION = '5.0.0'
                end
              end

              context 'and consumer_exit_after_fail is true' do
                before { allow(RabbitFeed.configuration).to receive(:consumer_exit_after_fail).and_return(true) }
                it 'notifies airbrake synchronously' do
                  expect(Airbrake).to receive(:notify_sync).with(an_instance_of RuntimeError)
                  expect{ subject.consume { raise 'Consuming time' } }.not_to raise_error
                end
              end

              context 'and consumer_exit_after_fail is not true' do
                before { allow(RabbitFeed.configuration).to receive(:consumer_exit_after_fail).and_return(false) }
                it 'notifies airbrake' do
                  expect(Airbrake).to receive(:notify).with(an_instance_of RuntimeError)
                  expect{ subject.consume { raise 'Consuming time' } }.not_to raise_error
                end
              end
            end
          end

          it 'negatively acknowledges the message' do
            expect(bunny_channel).to receive(:nack)
            subject.consume { raise 'Consuming time' }
          end
        end

      end
    end
  end
end
