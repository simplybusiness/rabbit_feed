module RabbitFeed
  class EventRouting
    class Event
      include ActiveModel::Validations

      attr_reader :name, :action
      validates_presence_of :name, :action
      validate :action_arity

      def initialize(name, block)
        @name   = name
        @action = block

        validate!
      end

      def handle_event(event)
        action.call event
      end

      private

      def action_arity
        errors.add(:action, 'arity should be 1') if action.present? && action.arity != 1
      end

      def validate!
        raise ConfigurationError, "Bad event specification for #{name}: #{errors.messages}" if invalid?
      end
    end

    class Application
      include ActiveModel::Validations

      attr_reader :named_events, :catch_all_event, :name
      validates_presence_of :name

      def initialize(name)
        @name         = name
        @named_events = {}

        validate!
      end

      def event(name, &block)
        if name == :any
          accept_any_event(&block)
        else
          accept_named_event(name, &block)
        end
      end

      def accepted_routes
        all_events.map do |event|
          "#{RabbitFeed.environment}#{RabbitFeed.configuration.route_prefix_extension}.#{name}.#{event.name}"
        end
      end

      def handle_event(event)
        event_rule = find_event event
        event_rule.handle_event event
      end

      def handles_event?(event)
        (find_event event).present?
      end

      private

      def validate!
        raise ConfigurationError, "Bad application specification for #{name}: #{errors.messages}" if invalid?
      end

      def accept_named_event(name, &block)
        raise ConfigurationError, "Routing has already been defined for the event with name: #{name} in application: #{self.name}" if named_events.key? name
        event = (Event.new name, block)
        named_events[event.name] = event
      end

      def accept_any_event(&block)
        raise ConfigurationError, "Routing has already been defined for the event catch-all: :any in application: #{name}" if catch_all_event.present?
        event = (Event.new '*', block)
        @catch_all_event = event
      end

      def find_event(event)
        [named_events[event.name], catch_all_event].compact.first
      end

      def all_events
        events = named_events.values
        events << catch_all_event if catch_all_event.present?
        events
      end
    end

    attr_reader :named_applications, :catch_all_application

    def initialize
      @named_applications = {}
    end

    def accept_from(name, &block)
      if name == :any
        accept_from_any_application(&block)
      else
        accept_from_named_application(name, &block)
      end
    end

    def accepted_routes
      routes = named_applications.values.flat_map(&:accepted_routes)
      routes += catch_all_application.accepted_routes if catch_all_application.present?
      routes
    end

    def handle_event(event)
      application = find_application event
      raise RoutingError, "No routing defined for application with name: #{event.application} for events named: #{event.name}" unless application.present?
      application.handle_event event
    end

    private

    def accept_from_named_application(name, &block)
      raise ConfigurationError, "Routing has already been defined for the application with name: #{name}" if named_applications.key? name
      application = Application.new name
      application.instance_eval(&block)
      named_applications[application.name] = application
    end

    def accept_from_any_application(&block)
      raise ConfigurationError, 'Routing has already been defined for the application catch-all: :any' if catch_all_application.present?
      application = Application.new '*'
      application.instance_eval(&block)
      @catch_all_application = application
    end

    def find_application(event)
      candidate_applications = [named_applications[event.application], catch_all_application].compact
      candidate_applications.detect do |application|
        application.handles_event? event
      end
    end
  end
end
