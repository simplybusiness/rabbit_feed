module RabbitFeed
  class EventRouting

    class Event
      include ActiveModel::Validations

      attr_reader :name, :action
      validates_presence_of :name, :action
      validate :action_arity

      def initialize name, block
        @name   = name
        @action = block

        validate!
      end

      def handle_event event
        action.call event
      end

      private

      def action_arity
        errors.add(:action, 'arity should be 1') if action.present? && action.arity != 1
      end

      def validate!
        raise ConfigurationError.new "Bad event specification for #{name}: #{errors.messages}" if invalid?
      end
    end

    class Application
      include ActiveModel::Validations

      attr_reader :events, :name
      validates_presence_of :name

      def initialize name
        @name    = name
        @events  = {}

        validate!
      end

      def event name, &block
        event = (Event.new name, block)
        events[event.name] = event
      end

      def accepted_routes
        events.values.map do |event|
          "#{RabbitFeed.environment}.#{name}.#{event.name}"
        end
      end

      def handle_event event
        event_rule = events[event.name]
        raise RoutingError.new "No routing defined for application with name: #{event.application} for events named: #{event.name}" unless event_rule.present?
        event_rule.handle_event event
      end

      def validate!
        raise ConfigurationError.new "Bad application specification for #{name}: #{errors.messages}" if invalid?
      end
    end

    attr_reader :named_applications, :catch_all_application

    def initialize
      @named_applications = {}
    end

    def accept_from name, &block
      if name == :any
        accept_from_any_application &block
      else
        accept_from_named_application name, &block
      end
    end

    def accepted_routes
      routes = named_applications.values.map{|application| application.accepted_routes }.flatten
      routes += catch_all_application.accepted_routes if catch_all_application.present?
      routes
    end

    def handle_event event
      application = find_application event.application
      raise RoutingError.new "No routing defined for application with name: #{event.application}" unless application.present?
      application.handle_event event
    end

    private

    def accept_from_named_application name, &block
      raise ConfigurationError.new "Routing has already been defined for the application with name: #{name}" if (named_applications.has_key? name)
      application = Application.new name
      application.instance_eval(&block)
      named_applications[application.name] = application
    end

    def accept_from_any_application &block
      raise ConfigurationError.new "Routing has already been defined for the application catch-all: :any" if catch_all_application.present?
      application = Application.new '*'
      application.instance_eval(&block)
      @catch_all_application = application
    end

    def find_application name
      named_applications[name] || catch_all_application
    end
  end
end
