module RabbitFeed
  class EventRouting

    class Application
      attr_reader :events, :name, :version

      def initialize name, version
        @name    = name
        @version = version
        @events  = []
      end

      def event name
        events << name
      end

      def accepted_routes
        events.map do |event|
          "#{RabbitFeed.environment}.#{name}.#{version}.#{event}"
        end
      end
    end

    attr_reader :applications

    def initialize
      @applications = []
    end

    def accept_from options, &block
      application = Application.new options[:application], options[:version]
      application.instance_eval(&block)
      applications << application
    end

    def accepted_routes
      applications.map{|application| application.accepted_routes }.flatten
    end
  end
end
