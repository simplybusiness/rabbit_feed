module RabbitFeed
  class Event
    include ActiveModel::Validations

    attr_reader :schema, :payload, :metadata
    validates :schema, :payload, :metadata, presence: true

    def initialize schema, payload, metadata
      @schema   = schema
      @payload  = payload
      @metadata = metadata
      validate!
    end

    def self.from_pre_2_0 schema, payload_and_metadata
      metadata = {}
      %w( application name host version environment created_at_utc ).each do |field|
        metadata[field] = payload_and_metadata.delete field
      end
      new schema, payload_and_metadata, metadata
    end

    def serialize
      buffer = StringIO.new
      writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
      writer << { 'gem_version' => RabbitFeed::VERSION, 'metadata' => metadata, 'payload' => payload }
      writer.close
      buffer.string
    end

    def self.deserialize serialized_event
      datum_reader = Avro::IO::DatumReader.new
      reader       = Avro::DataFile::Reader.new (StringIO.new serialized_event), datum_reader
      event_hash   = nil
      reader.each do |datum|
        event_hash = datum
      end
      reader.close
      if event_hash.has_key? 'gem_version'
        new datum_reader.readers_schema, event_hash[:payload], event_hash[:metadata]
      else
        from_pre_2_0 datum_reader.readers_schema, event_hash
      end
    end

    private

    def validate!
      raise Error.new errors.messages if invalid?
    end
  end
end
