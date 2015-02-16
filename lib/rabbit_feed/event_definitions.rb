module RabbitFeed
  class EventDefinitions

    class Field
      include ActiveModel::Validations

      attr_reader :name, :type, :definition
      validates_presence_of :name, :type, :definition

      def initialize name, type, definition
        @name       = name
        @type       = type
        @definition = definition
        validate!
      end

      def schema
        { name: name, type: type, doc: definition }
      end

      private

      def validate!
        raise ConfigurationError.new "Bad field specification for #{name}: #{errors.messages}" if invalid?
      end
    end

    class Event
      include ActiveModel::Validations

      attr_reader :name, :definition, :version, :fields
      validates_presence_of :name, :definition, :version
      validate :schema_parseable
      validates :version, format: { with: /\A\d+\.\d+\.\d+\z/, message: 'must be in *.*.* format' }

      def initialize name, version
        @name    = name
        @version = version
        @fields  = []
      end

      def payload_contains &block
        self.instance_eval(&block)
      end

      def field name, options
        fields << (Field.new name, options[:type], options[:definition])
      end

      def defined_as &block
        @definition = block.call if block.present?
      end

      def payload_schema
        { name: "#{name}_payload", type: 'record', fields: fields.map(&:schema) }
      end

      def metadata_schema
        { name: 'event_metadata', type: 'record', fields: [
          (Field.new 'application',    'string', 'The name of the application that created the event'),
          (Field.new 'host',           'string', 'The hostname of the server on which the event was created'),
          (Field.new 'environment',    'string', 'The environment in which the event was created'),
          (Field.new 'version',        'string', 'The version of the event payload'),
          (Field.new 'name',           'string', 'The name of the event'),
          (Field.new 'created_at_utc', 'string', 'The UTC time that the event was created')
        ].map(&:schema) }
      end

      def event_schema
        [
          (Field.new 'gem_version',  'string', 'The version of rabbit feed when the event was generated').schema,
          { name: 'payload', type: payload_schema, doc: 'The event payload (defined by the source system)' },
          { name: 'metadata', type: metadata_schema, doc: 'The event metadata (defined by rabbit feed)' }
        ]
      end

      def schema
        @schema ||= (Avro::Schema.parse ({ name: name, type: 'record', doc: definition, fields: event_schema }.to_json))
      end

      def validate!
        raise ConfigurationError.new "Bad event specification for #{name}: #{errors.messages}" if invalid?
      end

      private

      def schema_parseable
        schema
      rescue => e
        errors.add(:fields, "could not be parsed into a schema, reason: #{e.message}")
      end
    end

    attr_reader :events

    def initialize
      @events = {}
    end

    def define_event name, options, &block
      events[name] = Event.new name, options[:version]
      events[name].instance_eval(&block)
      events[name].validate!
    end

    def [] name
      events[name]
    end
  end
end
