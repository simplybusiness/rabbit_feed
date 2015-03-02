module RabbitFeed
  class Event
    include ActiveModel::Validations

    attr_reader :schema, :payload, :metadata
    validates :metadata, presence: true
    validates :payload, length: { minimum: 0, allow_nil: false, message: 'can\'t be nil' }

    def initialize metadata, payload={}, schema=nil
      @schema   = schema
      @payload  = payload.with_indifferent_access if payload
      @metadata = metadata.with_indifferent_access if metadata
      validate!
    end

    def serialize
      buffer = StringIO.new
      writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
      writer << { 'metadata' => metadata, 'payload' => payload }
      writer.close
      buffer.string
    end

    class << self

      def deserialize serialized_event
        datum_reader = Avro::IO::DatumReader.new
        reader       = Avro::DataFile::Reader.new (StringIO.new serialized_event), datum_reader
        event_hash   = nil
        reader.each do |datum|
          event_hash = datum
        end
        reader.close
        if (version_1? event_hash)
          new_from_version_1 event_hash, datum_reader.readers_schema
        else
          new event_hash['metadata'], event_hash['payload'], datum_reader.readers_schema
        end
      end

      private

      def version_1? event_hash
        %w(metadata payload).none?{|key| event_hash.has_key? key}
      end

      def new_from_version_1 metadata_and_payload, schema
        metadata = {}
        %w(application name host version environment created_at_utc).each do |field|
          metadata[field] = metadata_and_payload.delete field
        end
        new metadata, metadata_and_payload, schema
      end
    end

    private

    def validate!
      raise Error.new "Invalid event: #{errors.messages}" if invalid?
    end
  end
end
