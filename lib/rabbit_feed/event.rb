module RabbitFeed
  class Event
    attr_reader :environment, :application, :version, :name, :created_at_utc, :payload

    def initialize application, version, name, payload
      @application    = application
      @version        = version
      @name           = name
      @environment    = RabbitFeed.environment
      @created_at_utc = Time.now.utc
      @payload        = payload
    end

    def serialize
      YAML::dump self
    end

    def self.deserialize event
      YAML::load event
    end
  end
end
