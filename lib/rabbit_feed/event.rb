module RabbitFeed
  class Event
    include ActiveModel::Validations

    attr_reader :environment, :application, :version, :name, :host, :created_at_utc, :payload
    validates_presence_of :environment, :application, :version, :name, :created_at_utc, :payload

    def initialize application, version, name, payload
      @application    = application
      @version        = version
      @name           = name
      @host           = Socket.gethostname
      @environment    = RabbitFeed.environment
      @created_at_utc = Time.now.utc
      @payload        = payload
      validate!
    end

    def routing_key
      # "#{environment}.#{application}.#{version}.#{name}"
    end

    def serialize
      YAML::dump self
    end

    def self.deserialize event
      YAML::load event
    end

    private

    def validate!
      raise Error.new errors.messages if invalid?
    end
  end
end
