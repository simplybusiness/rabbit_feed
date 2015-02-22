require 'spec_helper'

module RabbitFeed
  describe Event do
    let(:schema)   { double(:schema) }
    let(:payload)  { { 'customer_id' => '123' } }
    let(:metadata) { { 'name' => 'test_event' } }

    subject { described_class.new metadata, payload, schema  }

    describe '.new' do

      it { should be_valid }
      its(:schema)   { should eq schema }
      its(:payload)  { should eq({ 'customer_id' => '123' }) }
      its(:metadata) { should eq({ 'name' => 'test_event' }) }

      context 'when payload is nil' do
        let(:payload) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Invalid event: {:payload=>["can\'t be nil"]}'
        end
      end

      context 'when metadata is blank' do
        let(:metadata) {}

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Invalid event: {:metadata=>["can\'t be blank"]}'
        end
      end
    end

    describe '.from_pre_2_0' do
      let(:metadata_and_payload) do
        {
          'application'    => 'rabbit_feed',
          'name'           => 'test_event',
          'host'           => 'localhost',
          'version'        => '1.0.0',
          'environment'    => 'test',
          'created_at_utc' => '2015-02-22',
          'customer_id'    => '123',
        }
      end
      subject{ described_class.from_pre_2_0 metadata_and_payload, 'no schema' }

      it { should be_valid }
      its(:schema)   { should eq 'no schema' }
      its(:payload)  { should eq({ 'customer_id' => '123' }) }
      its(:metadata) { should eq({
        'application'    => 'rabbit_feed',
        'name'           => 'test_event',
        'host'           => 'localhost',
        'version'        => '1.0.0',
        'environment'    => 'test',
        'created_at_utc' => '2015-02-22',
        })}
    end
  end
end
