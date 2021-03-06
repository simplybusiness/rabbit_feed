module RabbitFeed
  class Event
    include ActiveModel::Validations

    SCHEMA_VERSION = '2.0.0'.freeze

    attr_reader :schema, :payload, :metadata, :sensitive_fields
    validates :metadata, presence: true
    validates :payload, length: { minimum: 0, allow_nil: false, message: 'can\'t be nil' }
    validate  :required_metadata

    def initialize(metadata, payload = {}, schema = nil, sensitive_fields = [])
      @schema   = schema
      @payload  = payload.with_indifferent_access if payload
      @metadata = metadata.with_indifferent_access if metadata
      @sensitive_fields = Array(sensitive_fields).map(&:to_s).flatten
      validate!
    end

    def serialize
      buffer = StringIO.new
      writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
      writer << { 'metadata' => metadata, 'payload' => payload }
      writer.close
      buffer.string
    rescue Avro::IO::AvroTypeError
      raise Avro::IO::AvroTypeError.new(schema, sensitive_proof_payload)
    end

    def application
      metadata[:application]
    end

    def name
      metadata[:name]
    end

    def created_at_utc
      (Time.iso8601 metadata[:created_at_utc]) if metadata[:created_at_utc].present?
    end

    class << self
      def deserialize(serialized_event)
        datum_reader = Avro::IO::DatumReader.new
        reader       = Avro::DataFile::Reader.new (StringIO.new serialized_event), datum_reader
        event_hash   = nil
        reader.each do |datum|
          event_hash = datum
        end
        reader.close
        new event_hash['metadata'], event_hash['payload'], datum_reader.readers_schema
      end
    end

    private

    def sensitive_proof_payload
      sensitive_fields.each_with_object(payload.dup) do |field, clean_payload|
        clean_payload[field] = '[REMOVED]' if clean_payload.key?(field)
      end
    end

    def validate!
      raise Error, "Invalid event: #{errors.messages}" if invalid?
    end

    def required_metadata
      return unless metadata
      errors.add(:metadata, 'name field is required') if metadata[:name].blank?
    end
  end
end
