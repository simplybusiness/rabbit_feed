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

    attr_reader :applications

    def initialize
      @applications = {}
    end

    def accept_from name, &block
      application = Application.new name
      application.instance_eval(&block)
      applications[application.name] = application
    end

    def accepted_routes
      applications.values.map{|application| application.accepted_routes }.flatten
    end

    def handle_event event
      application = applications[event.application]
      raise RoutingError.new "No routing defined for application with name: #{event.application}" unless application.present?
      application.handle_event event
    end
  end
end
