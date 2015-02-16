require 'spec_helper'

module RabbitFeed
  describe Event do
    let(:schema)    { double(:schema) }
    let(:payload)   { { 'customer_id' => '123' } }
    let(:name)      { 'event_name' }
    let(:timestamp) { Time.iso8601 '2015-02-16T10:22:36.132841Z' }
    let(:version)   { '1.0.0' }
    let(:metadata)  { (PublishingOptions.new name, timestamp, version).metadata }

    subject { described_class.new schema, payload, metadata }

    describe '.new' do

      it { should be_valid }
      its(:schema)         { should eq schema }
      its(:payload)        { should eq({ 'customer_id' => '123' }) }
      its(:name)           { should eq('event_name') }
      its(:version)        { should eq('1.0.0') }
      its(:application)    { should eq('rabbit_feed') }
      its(:host)           { should eq(Socket.gethostname) }
      its(:created_at_utc) { should eq(timestamp) }
      its(:environment)    { should eq('test') }

      context 'when schema is nil' do
        let(:schema) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:schema=>["can\'t be blank"]}'
        end
      end

      context 'when payload is nil' do
        let(:payload) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:payload=>["can\'t be nil"]}'
        end
      end

      context 'when the application is nil' do
        before{ metadata.delete 'application' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:application=>["can\'t be blank"]}'
        end
      end

      context 'when the name is nil' do
        before{ metadata.delete 'name' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:name=>["can\'t be blank"]}'
        end
      end

      context 'when the version is nil' do
        before{ metadata.delete 'version' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:version=>["can\'t be blank"]}'
        end
      end

      context 'when the host is nil' do
        before{ metadata.delete 'host' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:host=>["can\'t be blank"]}'
        end
      end

      context 'when the created_at_utc is nil' do
        before{ metadata.delete 'created_at_utc' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:created_at_utc=>["can\'t be blank"]}'
        end
      end

      context 'when the environment is nil' do
        before{ metadata.delete 'environment' }

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Event is invalid due to the following validation errors: {:environment=>["can\'t be blank"]}'
        end
      end
    end
  end
end
