require 'spec_helper'

describe RabbitFeed::Configuration do

  describe '.load' do
    let(:file_path)   { 'spec/fixtures/configuration.yml' }
    let(:environment) { 'test' }
    subject { described_class.load file_path, environment }

    context 'with missing configuration' do
      let(:environment) { 'production' }

      it 'should raise an error' do
        expect{ subject }.to raise_error RabbitFeed::ConfigurationError
      end
    end

    context 'with configuration' do

      its(:host)        { should eq 'host_name' }
      its(:port)        { should eq 12345 }
      its(:user)        { should eq 'user_name' }
      its(:password)    { should eq 'password' }
      its(:application) { should eq 'rabbit_feed' }
      its(:environment) { should eq 'test' }
      its(:version)     { should eq '1.0.0' }
      its(:exchange)    { should eq 'exchange_name' }
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

      its(:host)     { should eq 'localhost' }
      its(:port)     { should eq 5672 }
      its(:user)     { should eq 'guest' }
      its(:password) { should eq 'guest' }
      its(:exchange) { should eq 'amq.topic' }
    end

    context 'with provided options' do
      let(:options) do
        {
          host:        'host_name',
          port:        12345,
          user:        'user_name',
          password:    'password',
          application: 'rabbit_feed',
          environment: 'test',
          version:     '1.0.0',
          exchange:    'exchange_name',
        }
      end

      its(:host)        { should eq 'host_name' }
      its(:port)        { should eq 12345 }
      its(:user)        { should eq 'user_name' }
      its(:password)    { should eq 'password' }
      its(:application) { should eq 'rabbit_feed' }
      its(:environment) { should eq 'test' }
      its(:version)     { should eq '1.0.0' }
      its(:exchange)    { should eq 'exchange_name' }
    end

    context 'with empty options' do

      it 'should raise an error' do
        expect{ subject }.to raise_error RabbitFeed::ConfigurationError
      end
    end
  end

end
