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

      context 'when name is blank' do
        let(:metadata) {{ 'name' => '' }}

        it 'should raise an error' do
          expect{ subject }.to raise_error 'Invalid event: {:metadata=>["name field is required"]}'
        end
      end
    end

    describe '#name' do
      let(:metadata) { { 'name' => 'test_event' } }

      its(:name) { should eq('test_event') }
    end

    describe '#application' do
      let(:metadata) { { 'name' => 'test_event', 'application' => 'test_application' } }

      its(:application) { should eq('test_application') }
    end

    describe '#created_at_utc' do

      context 'when the created_at_utc is in the metadata' do
        let(:metadata) { { 'name' => 'test_event', 'created_at_utc' => '2015-03-02T15:55:19.411299Z' } }

        its(:created_at_utc) { should eq(Time.iso8601('2015-03-02T15:55:19.411299Z')) }
      end

      context 'when the created_at_utc is not in the metadata' do
        let(:metadata) { { 'name' => 'test_event', 'created_at_utc' => '' } }

        its(:created_at_utc) { should be_nil }
      end
    end

    describe '#serialize' do
      let(:schema) do
        Avro::Schema.parse(
          {
            name:   'example-1.0',
            type:   'record',
            fields: [
              {
                name: 'payload',
                type: {
                  name: 'event_payload',
                  type: 'record',
                  fields: [
                    { name: 'event_integer', type: 'int' },
                    { name: 'event_string',  type: 'string' },
                  ],
                },
              },
              {
                name: 'metadata',
                type: {
                  name: 'event_metadata',
                  type: 'record',
                  fields: [{ name: 'name', type: 'string' }],
                },
              },
            ],
          }.to_json
        )
      end

      context 'with invalid payload' do
        let(:payload)  { {
          'event_string'  => 'HIGHLY SENSITIVE',
          'event_integer' => 'incorrect',
        } }

        it 'raises an Exception' do
          expect {
            subject.serialize
          }.to raise_error(Avro::IO::AvroTypeError)
        end

        it 'can remove values from exception' do
          event = described_class.new(metadata, payload, schema, ['event_string'])
          exception_msg = nil
          begin
            event.serialize
          rescue Avro::IO::AvroTypeError => e
            exception_msg = e.message
          end
          expect(exception_msg).to_not be_nil
          expect(exception_msg).to_not include("INCORRECT")
          expect(exception_msg).to include('"event_string"=>"[REMOVED]"')
          expect(exception_msg).to include('"event_integer"=>"incorrect"')
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
