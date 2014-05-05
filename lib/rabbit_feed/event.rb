module RabbitFeed
  class Event
    include ActiveModel::Validations

    attr_reader :schema, :payload
    validates_presence_of :schema, :payload

    def initialize schema, payload
      @schema  = schema
      @payload = payload
      validate!
    end

    def serialize
      buffer = StringIO.new
      writer = Avro::DataFile::Writer.new buffer, (Avro::IO::DatumWriter.new schema), schema
      writer << payload
      writer.close
      buffer.string
    end

    def self.deserialize event
      datum_reader = Avro::IO::DatumReader.new
      reader       = Avro::DataFile::Reader.new (StringIO.new event), datum_reader
      payload      = nil
      reader.each do |datum|
        payload = datum
      end
      reader.close
      Event.new datum_reader.readers_schema, payload
    end

    def method_missing(method_name, *args, &block)
      payload[method_name.to_s]
    end

    private

    def validate!
      raise Error.new errors.messages if invalid?
    end
  end
end
