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

      attr_reader :events, :name, :version
      validates_presence_of :name, :version
      validates :version, format: { with: /\A(\d+|\*)\.(\d+|\*)\.(\d+|\*)\z/, message: 'must be in *.*.* format' }

      def initialize name, version
        @name    = name
        @version = version
        @events  = {}

        validate!
      end

      def event name, &block
        event = (Event.new name, block)
        events[event.name] = event
      end

      def accepted_routes
        events.values.map do |event|
          "#{RabbitFeed.environment}.#{name}.#{version}.#{event.name}"
        end
      end

      def handle_event event
        event_rule = events[event.name]
        raise RoutingError.new "No routing defined for application with name: #{event.application} and version: #{event.version} for events named: #{event.name}" unless event_rule.present?
        event_rule.handle_event event
      end

      def validate!
        raise ConfigurationError.new "Bad application specification for #{name} #{version}: #{errors.messages}" if invalid?
      end
    end

    attr_reader :applications

    def initialize
      @applications = {}
    end

    def accept_from options, &block
      application = Application.new options[:application], options[:version]
      application.instance_eval(&block)
      applications[application.name] ||= {}
      applications[application.name].merge!({application.version => application})
    end

    def accepted_routes
      applications.values.map{|applications_by_name| applications_by_name.values.map{|application| application.accepted_routes } }.flatten
    end

    def handle_event event
      applications_by_name = applications[event.application]
      raise RoutingError.new "No routing defined for application with name: #{event.application}" unless applications_by_name.present?
      application          = applications_by_name[event.version]
      raise RoutingError.new "No routing defined for application with name: #{event.application} and version: #{event.version}" unless application.present?
      application.handle_event event
    end
  end
end
