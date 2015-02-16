module RabbitFeed
  class Event
    include ActiveModel::Validations

    attr_reader :schema, :payload, :application, :host, :environment, :created_at_utc, :version, :name
    validates :schema, :application, :host, :environment, :created_at_utc, :version, :name, presence: true
    validates :payload, length: { minimum: 0, allow_nil: false, message: 'can\'t be nil' }

    def initialize schema, payload, metadata
      @schema         = schema
      @payload        = payload.with_indifferent_access.freeze if payload
      @application    = metadata['application']
      @host           = metadata['host']
      @environment    = metadata['environment']
      @created_at_utc = Time.iso8601 metadata['created_at_utc'] if metadata['created_at_utc']
      @version        = metadata['version']
      @name           = metadata['name']
      validate!
    end

    def serialize
      buffer = StringIO.new
      writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
      writer << payload
      writer.close
      buffer.string
    end

    def self.deserialize serialized_payload, metadata
      datum_reader = Avro::IO::DatumReader.new
      reader       = Avro::DataFile::Reader.new (StringIO.new serialized_payload), datum_reader
      payload      = nil
      reader.each do |datum|
        payload = datum
      end
      reader.close
      Event.new datum_reader.readers_schema, payload, metadata
    end

    private

    def validate!
      raise Error.new "Event is invalid due to the following validation errors: #{errors.messages}" if invalid?
    end
  end
end
