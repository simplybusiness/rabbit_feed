module RabbitFeed
  class EventDefinitions

    class Dimension
      include ActiveModel::Validations

      class Field
        include ActiveModel::Validations

        attr_reader :name, :type, :definition
        validates_presence_of :name, :type, :definition

        def initialize name, type, definition
          @name       = name
          @type       = type
          @definition = definition
        end

        def schema
          { name: name, type: type, doc: definition }
        end
      end

      attr_reader :name, :fields, :definition, :version
      validates_presence_of :name, :fields, :definition, :version

      def initialize name, version
        @name    = name
        @version = version
        @fields  = []
      end

      def field name, options
        fields << (Field.new name, options[:type], options[:definition])
      end

      def defined_as &block
        @definition = block.call if block.present?
      end

      def schema
        {
          name:    name,
          type:    'record',
          doc:     definition,
          fields:  fields.map(&:schema) + [{ name: 'version', type: 'string' }],
        }
      end
    end

    class Event
      include ActiveModel::Validations

      attr_reader :name, :dimensions, :definition, :version, :dimension_names
      validates_presence_of :name, :dimensions, :definition, :version

      def initialize name, version
        @name       = name
        @version    = version
        @dimensions = []
      end

      def payload_contains *dimension_names
        @dimension_names = dimension_names
      end

      def add_dimension dimension
        @dimensions << dimension
      end

      def defined_as &block
        @definition = block.call if block.present?
      end

      def fields
        dimensions.map do |dimension|
          { name: dimension.name, type: dimension.schema }
        end + [
          { name: 'application',    type: 'string' },
          { name: 'host',           type: 'string' },
          { name: 'environment',    type: 'string' },
          { name: 'version',        type: 'string' },
          { name: 'created_at_utc', type: 'float'  }
        ]
      end

      def schema
        { name: name, type: 'record', doc: definition, fields: fields }.to_json
      end
    end

    attr_reader :dimensions, :events

    def initialize
      @dimensions = {}
      @events     = {}
    end

    def dimension name, options, &block
      dimensions[name] = Dimension.new name, options[:version]
      dimensions[name].instance_eval(&block)
    end

    def event name, options, &block
      events[name] = Event.new name, options[:version]
      events[name].instance_eval(&block)
      dimension_names = events[name].dimension_names
      dimension_names.each do |dimension_name|
        events[name].add_dimension dimensions[dimension_name]
      end
    end

    def [] name
      events[name]
    end
  end
end
