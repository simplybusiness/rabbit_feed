require 'spec_helper'

module RabbitFeed
  describe Configuration do

    describe '#queue' do
      let(:options) do
        {
          application: 'rabbit_feed',
          environment: 'test',
        }
      end
      subject { (described_class.new options).queue }

      it { should eq 'test.rabbit_feed' }
    end

    describe '#connection_options' do
      subject { (described_class.new options).connection_options }

      context 'when there are no defaults' do
        let(:options) do
          {
            application: 'rabbit_feed',
            environment: 'test',
          }
        end

        it { should include(logger: RabbitFeed.log) }
        it { should include(recover_from_connection_close: true) }
        it { should include(threaded: true) }
        it { should_not include(:heartbeat) }
        it { should_not include(:network_recovery_interval) }
        it { should_not include(:connect_timeout) }
        it { should_not include(:host) }
        it { should_not include(:user) }
        it { should_not include(:password) }
        it { should_not include(:port) }
      end

      context 'when there are defaults' do
        let(:options) do
          {
            application:    'rabbit_feed',
            environment:    'test',
            heartbeat:       5,
            connect_timeout: 1,
            host:            'localhost',
            user:            'guest',
            password:        'guest',
            port:            1234,
            network_recovery_interval: 1,
          }
        end

        it { should include(heartbeat: 5) }
        it { should include(connect_timeout: 1) }
        it { should include(host: 'localhost') }
        it { should include(user: 'guest') }
        it { should include(password: 'guest') }
        it { should include(port: 1234) }
        it { should include(network_recovery_interval: 1) }
        it { should include(logger: RabbitFeed.log) }
        it { should include(recover_from_connection_close: true) }
        it { should include(threaded: true) }
      end
    end

    describe '.load' do
      let(:file_path)   { 'spec/fixtures/configuration.yml' }
      let(:environment) { 'test' }
      subject { described_class.load file_path, environment }

      context 'with missing configuration' do
        let(:environment) { 'production' }

        it 'raises an error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end

      context 'with missing configuration file' do
        let(:file_path) { 'I do not exist' }

        it 'raises an error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end

      context 'with configuration' do

        its(:host)                      { should eq 'localhost' }
        its(:port)                      { should eq 5672 }
        its(:user)                      { should eq 'guest' }
        its(:password)                  { should eq 'guest' }
        its(:application)               { should eq 'rabbit_feed' }
        its(:environment)               { should eq 'test' }
        its(:exchange)                  { should eq 'rabbit_feed_exchange' }
        its(:pool_size)                 { should eq 1 }
        its(:pool_timeout)              { should eq 1 }
        its(:heartbeat)                 { should eq 60 }
        its(:connect_timeout)           { should eq 1 }
        its(:network_recovery_interval) { should eq 0.1 }
        its(:auto_delete_queue)         { should be_truthy }
        its(:auto_delete_exchange)      { should be_truthy }
      end

    end

    describe '.new' do
      let(:options) {{}}
      subject { described_class.new options }

      context 'with default options' do
        let(:options) do
          {
            application: 'rabbit_feed',
            environment: 'test',
          }
        end

        its(:host)                      { should be_nil }
        its(:port)                      { should be_nil }
        its(:user)                      { should be_nil }
        its(:password)                  { should be_nil }
        its(:heartbeat)                 { should be_nil }
        its(:network_recovery_interval) { should be_nil }
        its(:exchange)                  { should eq 'amq.topic' }
        its(:pool_size)                 { should eq 1 }
        its(:pool_timeout)              { should eq 120 }
        its(:connect_timeout)           { should be_nil }
        its(:auto_delete_queue)         { should be_falsey }
        its(:auto_delete_exchange)      { should be_falsey }
      end

      context 'with provided options' do
        let(:options) do
          {
            host:                      'host_name',
            port:                      12345,
            user:                      'user_name',
            password:                  'password',
            application:               'rabbit_feed',
            environment:               'test',
            exchange:                  'exchange_name',
            pool_size:                 2,
            pool_timeout:              6,
            heartbeat:                 3,
            connect_timeout:           4,
            network_recovery_interval: 2,
            auto_delete_queue:         'true',
            auto_delete_exchange:      'false',
          }
        end

        its(:host)                      { should eq 'host_name' }
        its(:port)                      { should eq 12345 }
        its(:user)                      { should eq 'user_name' }
        its(:password)                  { should eq 'password' }
        its(:application)               { should eq 'rabbit_feed' }
        its(:environment)               { should eq 'test' }
        its(:exchange)                  { should eq 'exchange_name' }
        its(:pool_size)                 { should eq 1 }
        its(:pool_timeout)              { should eq 6 }
        its(:heartbeat)                 { should eq 3 }
        its(:connect_timeout)           { should eq 4 }
        its(:network_recovery_interval) { should eq 2 }
        its(:auto_delete_queue)         { should be_truthy }
        its(:auto_delete_exchange)      { should be_truthy }
      end

      context 'with empty options' do

        it 'should raise an error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end
    end
  end
end
