module RabbitFeed
  class PublishingOptions

    attr_reader :event_name, :timestamp, :version, :application, :host, :environment

    def initialize event_name, timestamp, version
      @event_name  = event_name
      @timestamp   = timestamp
      @version     = version
      @application = RabbitFeed.configuration.application
      @host        = Socket.gethostname
      @environment = RabbitFeed.environment
    end

    def to_h
      {
        routing_key: routing_key,
        type:        event_name,
        app_id:      application,
        timestamp:   timestamp.to_i,
        headers:     metadata,
      }
    end

    def metadata
      {
        'application'    => application,
        'host'           => host,
        'environment'    => environment,
        'created_at_utc' => timestamp.iso8601(6),
        'version'        => version,
        'name'           => event_name,
      }
    end

    private

    def routing_key
      "#{environment}.#{application}.#{event_name}"
    end
  end
end
