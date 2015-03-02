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

    describe '.deserialize' do
      subject { described_class.deserialize serialized_event }

      context 'from a post-1.0 event' do
        let(:schema) do
          Avro::Schema.parse ({ name: 'post-1.0', type: 'record', fields: [
            { name: 'payload', type: {
              name: 'event_payload', type: 'record', fields: [
                { name: 'customer_id', type: 'string' },
                ]
              },
            },
            { name: 'metadata', type: {
              name: 'event_metadata', type: 'record', fields: [
                { name: 'name', type: 'string' },
                ]
              },
            },
          ]}.to_json)
        end
        let(:serialized_event) { (described_class.new metadata, payload, schema).serialize }

        its(:schema)   { should eq schema }
        its(:payload)  { should eq({ 'customer_id' => '123' }) }
        its(:metadata) { should eq({ 'name' => 'test_event' }) }
      end

      context 'from a 1.0 event' do
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
        let(:schema) do
          Avro::Schema.parse ({ name: '1.0', type: 'record', fields: [
            { name: 'customer_id', type: 'string' },
            { name: 'application', type: 'string' },
            { name: 'name', type: 'string' },
            { name: 'host', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'environment', type: 'string' },
            { name: 'created_at_utc', type: 'string' },
          ]}.to_json)
        end
        let(:serialized_event) do
          buffer = StringIO.new
          writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
          writer << metadata_and_payload
          writer.close
          buffer.string
        end

        its(:schema)   { should eq schema }
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
end
