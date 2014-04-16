require 'spec_helper'

module RabbitFeed
  describe Configuration do

    describe '.load' do
      let(:file_path)   { 'spec/fixtures/configuration.yml' }
      let(:environment) { 'test' }
      subject { described_class.load file_path, environment }

      context 'with missing configuration' do
        let(:environment) { 'production' }

        it 'should raise an error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end

      context 'with configuration' do

        its(:host)            { should eq 'localhost' }
        its(:port)            { should eq 5672 }
        its(:user)            { should eq 'guest' }
        its(:password)        { should eq 'guest' }
        its(:application)     { should eq 'rabbit_feed' }
        its(:environment)     { should eq 'test' }
        its(:version)         { should eq '1.0.0' }
        its(:exchange)        { should eq 'amq.topic' }
        its(:pool_size)       { should eq 1 }
        its(:pool_timeout)    { should eq 1 }
        its(:heartbeat)       { should eq 1 }
        its(:connect_timeout) { should eq 1 }
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
            version:     '1.0.0',
          }
        end

        its(:host)            { should eq 'localhost' }
        its(:port)            { should eq 5672 }
        its(:user)            { should eq 'guest' }
        its(:password)        { should eq 'guest' }
        its(:exchange)        { should eq 'amq.topic' }
        its(:pool_size)       { should eq 1 }
        its(:pool_timeout)    { should eq 5 }
        its(:heartbeat)       { should eq 5 }
        its(:connect_timeout) { should eq 10 }
      end

      context 'with provided options' do
        let(:options) do
          {
            host:            'host_name',
            port:            12345,
            user:            'user_name',
            password:        'password',
            application:     'rabbit_feed',
            environment:     'test',
            version:         '1.0.0',
            exchange:        'exchange_name',
            pool_size:       2,
            pool_timeout:    6,
            heartbeat:       3,
            connect_timeout: 4,
          }
        end

        its(:host)           { should eq 'host_name' }
        its(:port)           { should eq 12345 }
        its(:user)           { should eq 'user_name' }
        its(:password)       { should eq 'password' }
        its(:application)    { should eq 'rabbit_feed' }
        its(:environment)    { should eq 'test' }
        its(:version)        { should eq '1.0.0' }
        its(:exchange)       { should eq 'exchange_name' }
        its(:pool_size)      { should eq 2 }
        its(:pool_timeout)   { should eq 6 }
        its(:heartbeat)      { should eq 3 }
        its(:connect_timeout) { should eq 4 }
      end

      context 'with empty options' do

        it 'should raise an error' do
          expect{ subject }.to raise_error ConfigurationError
        end
      end
    end
  end
end
